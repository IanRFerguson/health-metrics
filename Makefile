ruff:
	@ruff check --fix .
	@ruff format .


server:
	@docker compose up app --build