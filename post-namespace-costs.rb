#!/usr/bin/env ruby

require "fileutils"
require "json"
require "open3"

ENV_REPO = "cloud-platform-environments"
CLUSTER = "live-1.cloud-platform.service.justice.gov.uk"
DATADIR = "/root/data"

def main
  kops_export
  checkout_env_repo
  FileUtils.mkdir_p(DATADIR)

  # This may fail before it posts the complete list, because the container
  # may run out of space due to having to keep reinstalling terraform
  # providers. So, we shuffle the list of namespaces so that, eventually
  # we'll get through the whole list, if this happens.
  namespaces
    .shuffle
    .each { |namespace| post_costs_to_hoodaw(namespace) }
end

def post_costs_to_hoodaw(namespace)
  puts namespace
  tfinit(namespace)
  json = execute "cd #{tfdir(namespace)}; infracost --tfdir . -o json"
  datafile = "#{DATADIR}/#{namespace}.json"
  File.write(datafile, json)
  post_json(namespace, datafile)
rescue => e
  # Terraform init and/or infracost may fail on a particular namespace,
  # but we don't want that to halt processing of other namespaces.
  puts "ERROR processing #{namespace}:\n#{e.message}"
  puts "Continuing to next namespace"
end

def post_json(namespace, file)
  api_key = ENV.fetch("HOODAW_API_KEY")
  host = ENV.fetch("HOODAW_HOST")
  url = "#{host}/namespace/costs/#{namespace}"
  cmd = %[curl -H "X-API-KEY: #{api_key}" -d "$(cat #{file})" #{url}]
  execute cmd
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

def namespaces
  Dir[tfdir("*")].map { |s| s.split("/")[-2] }
end

def tfdir(namespace)
  "#{ENV_REPO}/namespaces/#{CLUSTER}/#{namespace}/resources"
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

def execute(cmd)
  puts "CMD: #{cmd}"
  stdout, stderr, status = Open3.capture3(cmd)
  puts "OUTPUT:\n#{stdout}"
  unless status.success?
    puts "ERROR: #{stderr}"
    exit 1
  end
  stdout
end

main
