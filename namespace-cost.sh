#!/bin/sh

kops export kubecfg live-1.cloud-platform.service.justice.gov.uk

git clone --depth 1 https://github.com/ministryofjustice/cloud-platform-environments.git

export NAMESPACE=cccd-staging

cd cloud-platform-environments/namespaces/live-1.cloud-platform.service.justice.gov.uk/${NAMESPACE}/resources/

terraform init \
  -backend-config="bucket=cloud-platform-terraform-state" \
  -backend-config="key=cloud-platform-environments/live-1.cloud-platform.service.justice.gov.uk/${NAMESPACE}/terraform.tfstate" \
  -backend-config="region=eu-west-1" \
  -backend-config="dynamodb_table=cloud-platform-environments-terraform-lock"

infracost --tfdir .
