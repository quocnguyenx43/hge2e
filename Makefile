# Declare all phony targets
.PHONY: init oltp 

# Configuration
OLTP_COMPOSE_FILE := docker-compose.oltp.yaml
HADOOP_COMPOSE_FILE := docker-compose.hadoop.yaml
SPARK_COMPOSE_FILE := docker-compose.spark.yaml
HIVE_COMPOSE_FILE := docker-compose.hive.yaml
TRINO_COMPOSE_FILE := docker-compose.trino.yaml
SUPERSET_COMPOSE_FILE := docker-compose.superset.yaml
COMPOSE_BAKE := COMPOSE_BAKE=true
PYTHON := python3

# Using shared network accross all services
init:
	docker network create hg-e2e

# ====== Up Targets ======
oltp:
	$(COMPOSE_BAKE) docker compose -f $(OLTP_COMPOSE_FILE) up -d --build

hadoop:
	$(COMPOSE_BAKE) docker compose -f $(HADOOP_COMPOSE_FILE) up -d --build

spark:
	$(COMPOSE_BAKE) docker compose -f $(SPARK_COMPOSE_FILE) up -d --build

hive:
	$(COMPOSE_BAKE) docker compose -f $(HIVE_COMPOSE_FILE) up -d --build

trino:
	$(COMPOSE_BAKE) docker compose -f $(TRINO_COMPOSE_FILE) up -d --build

superset:
	$(COMPOSE_BAKE) docker compose -f $(SUPERSET_COMPOSE_FILE) up -d --build

# ====== Down Targets ======
oltp-down:
	docker compose -f $(OLTP_COMPOSE_FILE) down -v

hadoop-down:
	docker compose -f $(HADOOP_COMPOSE_FILE) down -v

spark-down:
	docker compose -f $(SPARK_COMPOSE_FILE) down -v

hive-down:
	docker compose -f $(HIVE_COMPOSE_FILE) down -v

trino-down:
	docker compose -f $(TRINO_COMPOSE_FILE) down -v

superset-down:
	docker compose -f $(SUPERSET_COMPOSE_FILE) down -v

# ====== Clean Targets ======
distclean:
	chmod +x ./distclean.sh && ./distclean.sh
