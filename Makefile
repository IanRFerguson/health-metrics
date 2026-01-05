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


pipeline:
	@docker compose up pipeline-load --build


pipeline-shell:
	@docker compose up pipeline-shell --build -d;
	@docker compose exec -it pipeline-shell bash


pipeline-docker-push:
	@docker build \
		-t us-central1-docker.pkg.dev/ian-is-online/health-metrics/pipeline-image:latest \
		-f ./devops/docker/Dockerfile.pipe \
		--platform linux/amd64 \
		.

	@docker push us-central1-docker.pkg.dev/ian-is-online/health-metrics/pipeline-image:latest