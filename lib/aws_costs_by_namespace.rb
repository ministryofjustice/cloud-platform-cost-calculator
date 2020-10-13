# Fetch AWS costs for a single day, broken down by namespace tag, and multiply
# all amounts by 30 to get monthly costs
class AwsCostsByNamespace
  attr_reader :date

  TAG = "namespace"
  SHARED_COSTS = "SHARED_COSTS"
  DAYS_PER_MONTH = 30 # An average, to convert daily amounts to monthly

  def initialize(params)
    @date = params.fetch(:date) # should be a Date object
  end

  def report
    tuples = data.map { |cost| hash_from_cost(cost) }

    costs = costs_by_namespace(tuples)

    shared_costs = costs.delete(SHARED_COSTS).values.sum
    shared_aws_per_namespace = shared_costs / costs.keys.size
    costs.values.each { |hash| hash["Shared AWS Costs"] = shared_aws_per_namespace }

    {
      TAG => add_totals(costs),
      updated_at: Time.now,
    }
  end

  private

  # Take output from AWS CostExplorer and convert to a hash
  #   { [namespace name] => {
  #     "breakdown" => {
  #       [resource type] => cost,
  #       ...
  #     },
  #     "total" => [monthly amount]
  #   }
  def costs_by_namespace(tuples)
    tuples.inject({}) do |acc, h|
      tag = h[:tag]
      resource = h[:resource]
      costs = acc[tag] || {}
      costs[resource] = costs[resource].to_f + h[:amount]
      acc[tag] = costs
      acc
    end
  end

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
    tag_value = SHARED_COSTS if tag_value == ""

    {
      resource: resource_type,
      tag: tag_value,
      amount: cost.metrics.fetch("BlendedCost").amount.to_f * DAYS_PER_MONTH
    }

  end
  def data
    ce = Aws::CostExplorer::Client.new(
      # todo: move to initialize
      region: "us-east-1", # CostExplorer only works with this region value
      access_key_id: ENV.fetch("AWS_ACCESS_KEY_ID"),
      secret_access_key: ENV.fetch("AWS_SECRET_ACCESS_KEY")
    )

    end_date = date.strftime("%Y-%m-%d")
    start_date = date.prev_day.strftime("%Y-%m-%d")

    data = ce.get_cost_and_usage(
      granularity: "DAILY",
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
          key: TAG
        }
      ]
    )

    raise "More than one page in response. Please add code to iterate over all response pages." if data.next_page?
    raise "More than one entry in results_by_time - I don't know how to handle that." if data.results_by_time.size > 1

    data.results_by_time.first.groups
  end
end
