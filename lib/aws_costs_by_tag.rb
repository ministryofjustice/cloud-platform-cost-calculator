# Fetch AWS costs for a period, broken down by a tag
class AwsCostsByTag
  attr_reader :tag, :year, :month

  def initialize(params)
    @tag = params.fetch(:tag)
    @year = params.fetch(:year)
    @month = params.fetch(:month)
  end

  def report
    tuples = data.map { |cost| hash_from_cost(cost) }

    costs_by_tag = tuples.inject({}) do |acc, h|
      tag = h[:tag]
      resource = h[:resource]
      costs = acc[tag] || {}
      costs[resource] = costs[resource].to_f + h[:amount]
      acc[tag] = costs
      acc
    end

    add_totals(costs_by_tag)
  end

  private

  # { foo: { a: 1, b: 2 } } -> { foo: { breakdown: { a: 1, b: 2 }, total: 3 } }
  def add_totals(hash)
    hash.inject({}) do |acc, (tag, costs)|
      acc[tag] = {
        breakdown: costs,
        total: costs.values.sum,
      }
      acc
    end
  end

  def hash_from_cost(cost)
    resource_type, tag_string = cost.keys
    tag_value = tag_string.split("$")[1].to_s
    {
      resource: resource_type,
      tag: tag_value,
      amount: cost.metrics.fetch("BlendedCost").amount.to_f
    }
  end

  def data
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
          key: tag
        }
      ]
    )

    raise "More than one page in response. Please add code to iterate over all response pages." if data.next_page?
    raise "More than one entry in results_by_time - I don't know how to handle that." if data.results_by_time.size > 1

    data.results_by_time.first.groups
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
