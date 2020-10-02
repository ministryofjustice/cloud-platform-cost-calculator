#!/usr/bin/env ruby

require "pry-byebug"
require "aws-sdk-costexplorer"
require "date"
require "fileutils"
require "json"
require "open3"

require_relative "./lib/aws_costs_by_tag"

ENV_REPO = "cloud-platform-environments"
CLUSTER = "live-1.cloud-platform.service.justice.gov.uk"
DATADIR = "./data"

def last_month
  year = Date.today.year
  month = Date.today.month
  if month == 1
    month = 12
    year -= 1
  else
    month -= 1
  end
  {month: month, year: year}
end

puts AwsCostsByTag.new(last_month.merge(tag: "namespace")).report.to_json
