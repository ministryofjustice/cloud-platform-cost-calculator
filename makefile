IMAGE := foo

.built: Dockerfile post-namespace-costs.rb
	docker build -t $(IMAGE) .
	touch .built

build: .built

run: build
	@docker run --rm \
		-e AWS_ACCESS_KEY_ID="$${AWS_ACCESS_KEY_ID}" \
		-e AWS_SECRET_ACCESS_KEY="$${AWS_SECRET_ACCESS_KEY}" \
    -e HOODAW_API_KEY="$${HOODAW_API_KEY}" \
    -e HOODAW_HOST="$${HOODAW_HOST}" \
	-it $(IMAGE) ./post-namespace-costs.rb
