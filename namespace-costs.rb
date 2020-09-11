#!/usr/bin/env ruby

require "json"
require "open3"
# require "pry-byebug"

ENV_REPO = "cloud-platform-environments"
CLUSTER = "live-1.cloud-platform.service.justice.gov.uk"
DATADIR = "/root/data"

# TODO: remove this. This limits the scope to 2 namespaces, rather than 200+
# because it takes a long time to run this report
NAMESPACES = ["cccd-staging", "laa-cla-backend-production"]

def main
  kops_export
  checkout_env_repo

  infracosts = namespaces.inject({}) do |hash, namespace|
    hash[namespace] = infracost(namespace)
    hash
  end

  rtn = {
    infracosts: infracosts,
    updated_at: Time.now
  }

  puts rtn.to_json
  # rtn = JSON.parse(File.read("costs.json"))
  # puts summarise(rtn).to_json
end

def summarise(infracost_data)
  rtn = infracost_data.fetch("infracosts").inject({}) do |hash, (namespace, data)|
    resource_costs = data.fetch("infracost").map {|c| { resource: c["name"], monthly_cost: c["monthlyCost"] } }
    hash[namespace] = {infracost: resource_costs}
    hash
  end

  rtn.each do |namespace, data|
    total = data[:infracost].map {|i| i[:monthly_cost].to_f}.sum
    rtn[namespace][:infracost_total] = total
  end

  rtn
end

# TODO: Use this in place of NAMESPACES, but it will take *hours* to run
def namespaces
  Dir[tfdir("*")].map {|s| s.split("/")[-2]}
end

def kops_export
  execute "kops export kubecfg #{CLUSTER}"
end

def checkout_env_repo
  execute("git clone --depth 1 https://github.com/ministryofjustice/#{ENV_REPO}.git")
end

def repo_url
  "https://github.com/ministryofjustice/#{ENV_REPO}.git"
end

def infracost(namespace)
  $stderr.puts namespace # TODO: add timestamped logging
  datafile = "#{DATADIR}/#{namespace}-cost.json"

  unless FileTest.exists?(datafile)
    tfinit(namespace)
    json = execute "cd #{tfdir(namespace)}; infracost --tfdir . -o json"
    File.write(datafile, json)
  end

  json = File.read(datafile)
  { infracost: JSON.parse(json) }
end

def tfinit(namespace)
  bucket = ENV.fetch("TF_VAR_cluster_state_bucket")

  # TODO: More of the strings below should probably be constants/env vars
  cmd = <<~EOF
    terraform init \
      -backend-config="bucket=#{bucket}" \
      -backend-config="key=#{ENV_REPO}/#{CLUSTER}/#{namespace}/terraform.tfstate" \
      -backend-config="region=eu-west-1" \
      -backend-config="dynamodb_table=cloud-platform-environments-terraform-lock"
  EOF
  execute "cd #{tfdir(namespace)}; #{cmd}"
end

def tfdir(namespace)
  "#{ENV_REPO}/namespaces/#{CLUSTER}/#{namespace}/resources"
end

def execute(cmd)
  # puts "CMD: #{cmd}"
  stdout, stderr, status = Open3.capture3(cmd)
  unless status.success?
    puts "ERROR: #{stderr}"
    exit 1
  end
  stdout
end

main
