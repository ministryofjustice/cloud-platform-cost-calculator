#!/usr/bin/env ruby

require "pry-byebug"
require "aws-sdk-costexplorer"
require "date"
require "fileutils"
require "json"
require "open3"

require_relative "./lib/aws_costs_by_namespace"

ENV_REPO = "cloud-platform-environments"
CLUSTER = "live-1.cloud-platform.service.justice.gov.uk"
DATADIR = "./data"

# TODO: Identify shared AWS costs
# TODO: Add shared team costs

yesterday = Date.today.prev_day

puts AwsCostsByNamespace.new(start_date: yesterday, end_date: Date.today).report.to_json
