# Cloud Platform Cost Calculator

[![Releases](https://img.shields.io/github/release/ministryofjustice/cloud-platform-cost-calculator/all.svg?style=flat-square)](https://github.com/ministryofjustice/cloud-platform-cost-calculator/releases)

Use [infracost] to work out the running costs of namespaces in the Cloud
Platform, and post the data to [How Out Of Date Are We][hoodaw]

## Shared AWS Costs

A portion of the shared AWS costs for running the platform are allocated to
each namespace. The total shared costs for the previous calendar month are
fetched via the AWS [cost explorer] API (identifying shared costs via the
"owner" tag - see the code for details), and a portion (total / number of
namespaces) is added to each namespace.

## Shared Support Costs

A portion of the total cost of the Cloud Platform is allocated to each namespace.
The total monthly team cost is hard-coded into the script and a portion (total
/ number of namespaces) is added to each namespace.

[infracost]: https://infracost.io
[hoodaw]: https://how-out-of-date-are-we.apps.live-1.cloud-platform.service.justice.gov.uk
[cost explorer]: https://aws.amazon.com/aws-cost-management/aws-cost-explorer/
