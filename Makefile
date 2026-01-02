ruff:
	@ruff check --fix .
	@ruff format .


server:
	@docker compose up app --build


server-docker-push:
	@docker build \
		-t us-central1-docker.pkg.dev/ian-is-online/health-metrics/app-image:latest \
		-f ./devops/docker/Dockerfile.server \
		--platform linux/amd64 \
		.

	@docker push us-central1-docker.pkg.dev/ian-is-online/health-metrics/app-image:latest