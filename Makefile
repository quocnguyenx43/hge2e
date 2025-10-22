default: up

init:
	docker network create hg-e2e

oltp:
	docker compose -f ./docker-compose.yaml up -d postgres

oltp-down:
	docker compose -f ./docker-compose.yaml down -v postgres

hadoop:
	docker compose -f ./docker-compose.yaml up -d

hadoop-down:
	docker compose -f ./docker-compose.yaml down -v

sqoop:
	docker compose -f ./docker-compose.yaml up -d

sqoop-down:
	docker compose -f ./docker-compose.yaml down -v

up: init postgres-down hadoop sqoop

down: postgres-down hadoop-down sqoop-down

distclean:
	find . -type d -name ".venv" -exec rm -rf {} +

	find . -type d -name "__pycache__" -exec rm -rf {} +
	find . -type d -name "*.egg-info" -exec rm -rf {} +
	find . -type d -name ".pytest_cache" -exec rm -rf {} +
	find . -type d -name ".mypy_cache" -exec rm -rf {} +
	find . -type d -name ".ruff_cache" -exec rm -rf {} +

	find . -type f -name "*.pyc" -delete
	find . -type f -name "*.pyo" -delete
	find . -type f -name "*.pyd" -delete
	find . -type f -name "*.coverage" -delete
	find . -type f -name ".coverage.*" -delete

	find ./data/nameNode -mindepth 1 ! -name '.gitkeep' -delete
	find ./data/secondaryNameNode -mindepth 1 ! -name '.gitkeep' -delete
	find ./data/dataNode1 -mindepth 1 ! -name '.gitkeep' -delete
	find ./data/dataNode2 -mindepth 1 ! -name '.gitkeep' -delete

.PHONY: postgres postgres-down \
		hadoop hadoop-down \
		sqoop sqoop-down \
		up down \
		distclean
