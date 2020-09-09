FROM alpine:3.12

ENV \
  KOPS_VERSION=1.15.3 \
  TERRAFORM_AUTH0_VERSION=0.2.1 \
  TERRAFORM_PINGDOM_VERSION=1.1.1 \
  TERRAFORM_VERSION=0.12.17 \
  PIPELINE_STATE_BUCKET=cloud-platform-terraform-state \
  PIPELINE_STATE_KEY_PREFIX="cloud-platform-environments/" \
  PIPELINE_TERRAFORM_STATE_LOCK_TABLE="cloud-platform-environments-terraform-lock" \
  PIPELINE_STATE_REGION="eu-west-1"

RUN apk --no-cache add git curl

# Install terraform
RUN curl -sL https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip | unzip -d /usr/local/bin -

# Install terraform auth0 provider
RUN mkdir -p /root/.terraform.d/plugins
RUN curl -sL https://github.com/yieldr/terraform-provider-auth0/releases/download/v${TERRAFORM_AUTH0_VERSION}/terraform-provider-auth0_v${TERRAFORM_AUTH0_VERSION}_linux_amd64.tar.gz | tar xzv  \
  && mv terraform-provider-auth0_v${TERRAFORM_AUTH0_VERSION} ~/.terraform.d/plugins/

# Install Pingdom provider
RUN wget https://github.com/russellcardullo/terraform-provider-pingdom/releases/download/v${TERRAFORM_PINGDOM_VERSION}/terraform-provider-pingdom_v${TERRAFORM_PINGDOM_VERSION}_linux_amd64_static \
  && chmod +x terraform-provider-pingdom_v${TERRAFORM_PINGDOM_VERSION}_linux_amd64_static \
  && mv terraform-provider-pingdom_v${TERRAFORM_PINGDOM_VERSION}_linux_amd64_static ~/.terraform.d/plugins/terraform-provider-pingdom_v${TERRAFORM_PINGDOM_VERSION}

# Install kops
RUN curl -sLo /usr/local/bin/kops https://github.com/kubernetes/kops/releases/download/v${KOPS_VERSION}/kops-linux-amd64

# Install infracost
RUN curl --silent --location "https://github.com/infracost/infracost/releases/latest/download/infracost-$(uname -s)-amd64.tar.gz" | tar xz -C /tmp \
  && mv /tmp/infracost-$(uname -s | tr '[:upper:]' '[:lower:]')-amd64 /usr/local/bin/infracost

# Ensure everything is executable
RUN chmod +x /usr/local/bin/*

ENV KOPS_STATE_STORE=s3://cloud-platform-kops-state

WORKDIR /root

RUN git clone --depth 1 https://github.com/ministryofjustice/cloud-platform-environments.git

COPY namespace-cost.sh .
COPY list.sh .
