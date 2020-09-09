IMAGE := foo

.built: Dockerfile
	docker build -t $(IMAGE) .

build: .built

run: build
	docker run --rm \
		-e AWS_ACCESS_KEY_ID="$${AWS_ACCESS_KEY_ID}" \
		-e AWS_SECRET_ACCESS_KEY="$${AWS_SECRET_ACCESS_KEY}" \
		-e AWS_REGION="$${AWS_REGION}" \
    -e TF_VAR_cluster_name="$${TF_VAR_cluster_name}" \
    -e TF_VAR_cluster_state_bucket="$${TF_VAR_cluster_state_bucket}" \
    -e TF_VAR_cluster_state_key="$${TF_VAR_cluster_state_key}" \
    -e  PIPELINE_STATE_BUCKET="$${PIPELINE_STATE_BUCKET}" \
    -e  PIPELINE_STATE_KEY_PREFIX="$${PIPELINE_STATE_KEY_PREFIX}" \
    -e  PIPELINE_TERRAFORM_STATE_LOCK_TABLE="$${PIPELINE_TERRAFORM_STATE_LOCK_TABLE}" \
    -e  PIPELINE_STATE_REGION="$${PIPELINE_STATE_REGION}" \
    -e  PINGDOM_PASSWORD="$${PINGDOM_PASSWORD}" \
    -e  PINGDOM_API_KEY="$${PINGDOM_API_KEY}" \
    -e  PINGDOM_USER="$${PINGDOM_USER}" \
	-it $(IMAGE) sh
