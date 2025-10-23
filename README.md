# Orchestration
- Airflow
    - ETL
    - CDC Backfills
    - ML Pipelines
    - Housekeeping

# Data Sources:
- PostgreSQL (OLTP)
- MySQL (OLTP)
- CDC
- External APIs
- Event streams

# Data Storage
- Data Lake: HDFS
- Table format: Apache Iceberg
- Layout:
    - bronze: copies, aditable, minimal schema evolution
    - silver: parsed, typed, deduped, PII handled, conformed dimensions
    - gold: star schema, data marts, feature tables
- Hive Metastore (Iceberg catalogs)

# Ingestion
- Spark (OLTP -> Hadoop)

# Batch Processing
- Spark SQL: tranform bronze -> [silver, gold]

# Streaming Processing
- CDC (Postgres -> Debezium -> Kafka)
- Schema Registry
- Flink:
    - jois/aggregations/enrichment -> Iceberg/Kafka sinks
- Spark Structured Streaming:
    - fraud/churn features -> ML pipelines
- Storm

# Warehouse / Dashboard
- Trino: interactive SQL on Iceberg/HDFS: "Top products clicked but not purchased"
- Hive
- Superset

# Serving
- HBase + Phoenix / FastAPI / Cassandra: real-time profile and feature lookups

# Search / Text analytics
- Solr: index curated documents, logs, or product catalogs; expose Solr SQL to BI or embed in FastAPI.

<!-- ### Analytics / ML
- Notebooks (Jupyter) on Spark or Pandas. → exploratory data analysis and ML training.
- Spark MLlib + Python (scikit-learn, XGBoost, LightGBM) on curated Iceberg tables. (churn prediction, fraud detection.)
- MLflow for experiment tracking & model registry (nice add).

### Ops / Governance
- Apache Ranger (authz), Apache Atlas (lineage), OpenLineage → Airflow.
- Prometheus + Grafana for metrics.
- Hue (nice SQL UI).
- Ambari: optional—use for cluster-management practice; not essential today. => Ansible + Prometheus/Grafana -->

# Lagacy Tools
- sqoop
- flume