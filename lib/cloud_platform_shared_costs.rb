# Class to return the USD amount of our AWS bill that represents shared costs
# (e.g. cluster nodes), as opposed to costs attributable to specific services
# which are *hosted* on the cloud platform.
class CloudPlatformSharedCosts
  attr_accessor :year, :month

  # Values of the "owner" tag which indicate that this is a shared cost.
  SHARED_COST_OWNERS = [
    "",
    "Cloud Platform",
    "cloud-platform",
    "cloud-platforms",
    "webops",
    "cloud-platform:platforms@digital.justice.gov.uk",
    "cloud platform",
    "Cloud Platforms platforms@digital.justice.gov.uk",
    "WebOps",
    "cloudplatform",
    "cloudplatformtest",
    "concourse",
    "live-1"
  ]

  def initialize(params)
    @year = params.fetch(:year)
    @month = params.fetch(:month)
  end

  def usd_amount
    shared_cost(cost_and_usage)
  end

  private

  def cost_and_usage
    ce = Aws::CostExplorer::Client.new(
      region: "us-east-1", # CostExplorer only works with this region value
      access_key_id: ENV.fetch("AWS_ACCESS_KEY_ID"),
      secret_access_key: ENV.fetch("AWS_SECRET_ACCESS_KEY")
    )

    data = ce.get_cost_and_usage(
      granularity: "MONTHLY",
      metrics: ["BlendedCost"],
      time_period: {
        start: start_date,
        end: end_date
      },
      group_by: [
        {
          type: "DIMENSION",
          key: "SERVICE"
        },
        {
          type: "TAG",
          key: "owner"
        }
      ]
    )

    raise "More than one page in response. Please add code to iterate over all response pages." if data.next_page?
    raise "More than one entry in results_by_time - I don't know how to handle that." if data.results_by_time.size > 1

    data
  end

  # This is only partially accurate, because our total tax amount and our total refund are both included in the shared costs.
  # It would be more accurate to assign a portion of both of these, pro rata, across all of our spend (e.g. if a service
  # accounts for 10% of our AWS bill, then it should also account for 10% of our tax and 10% of our refund), but this is
  # a reasonable first approximation.
  def shared_cost(data)
    data.results_by_time.first.groups
      .map { |group| service_owner_cost(group) }
      .filter { |c| SHARED_COST_OWNERS.include?(c[:owner]) }
      .sum { |c| c[:usd_amount] }
  end

  def service_owner_cost(group)
    {
      service: group.keys[0],
      owner: group.keys[1].sub("owner$", ""),
      usd_amount: group.metrics.fetch("BlendedCost").amount.to_f
    }
  end

  # Report start date is the first day of the month
  def start_date
    first_of_month(year, month)
  end

  # Report end date is the first day of the next month
  def end_date
    if month == 12
      y = year + 1
      m = 1
    else
      y = year
      m = month + 1
    end

    first_of_month(y, m)
  end

  def first_of_month(y, m)
    sprintf("%04d-%02d-%02d", y, m, 1)
  end
end
