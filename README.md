## High-Level Architecture

### Orchestration:
- Airflow: DAGs for batch ETL, CDC backfills, ML pipelines, housekeeping.

### Data Sources:
- Postgres (OLTP).
- MySQL (OLTP)
- External APIs.
- Event streams.

### Ingestion:

**Batch Ingestion**:
- Batch offloads: Kafka Connect JDBC (for simple tables) or Spark batch.
    - Postgres
    - MySQL
- Change Data Capture (CDC): Postgres → Debezium → Kafka (KRaft).
    - Postgres
    - MySQL
- Batch pulls / APIs: NiFi flows (REST → JSON/CSV/Parquet) → Kafka or lake.
- File drops / logs: Apps → Kafka; or NiFi tail/FetchFile → Kafka. 

**Message/Stream Bus**:
- Kafka (KRaft) with schemas in Confluent Schema Registry or Apicurio.
- **Kafka** → central event bus for streaming data.  
- **Generators** → fake clickstream + IoT data for simulation.

**Legacy Tools**:
- **Sqoop** → batch import of structured data into HDFS. (Infra + Sqoop → Hive (structured batch).)
- **Flume** → ingestion of logs/IoT data (JSON/XML) into Kafka/HDFS. (Kafka + Flume + Generators → HDFS (unstructured streaming).)

### Data Layering:
- Storage: HDFS.
- Table format: Apache Iceberg (recommended; ACID + time travel).
- Layout: /datalake/{raw|refined|curated}/… with Iceberg catalogs via Hive Metastore or Nessie.
    - raw/: exact source copies (CDC logs, JSON, CSV). Auditable, minimal schema evolution.
    - refined/: parsed, typed, deduped, PII handled, conformed dimensions.
    - curated/: star/snowflake marts, feature tables, KPIs—drives BI/ML and serving.

### Processing
- Flink SQL for streaming joins/aggregations/enrichment → Iceberg/Kafka sinks. joins clickstream with IoT streams in real time
    - flink run processing/flink/join_click_iot.sql
- Spark Structured Streaming for fraud/churn features/ML pipelines → Iceberg (fraud detection, churn prediction pipelines)
    - spark-submit processing/spark/fraud_detection.py
    - spark-submit processing/spark/churn_prediction.py
- Spark SQL for batch transforms (replaces Pig) and curation. (clean the raw data in HDFS (cleaning, jooining) and output into /datalake/processed/)
- (Optional) Storm: only if you specifically want to learn its model—Flink usually covers it. (lightweight anomaly detection on streams) device overheating events (Storm).

### Warehouse / BI
- Trino (Presto successor) and/or Impala for interactive SQL on Iceberg/HDFS. interactive analytics and dashboards => “Top products clicked but not purchased
- Hive (strictly as metastore/compat layer and batch SQL where helpful). batch SQL queries over HDFS (which zone to query)
    - beeline -u jdbc:hive2://hive-server:10000 -f warehouse/hive/analytics_queries.sql
- Apache Superset for dashboards.

### Serving
- HBase (with Phoenix) or Cassandra (with CQL): real-time profile and feature lookups
    - Use HBase+Phoenix if you want tight Hadoop integration and Phoenix SQL.
    - Use Cassandra if you prefer independent, multi-DC, high-throughput KV/TS workloads.
    - Load schemas from serving/hbase/.
    - Phoenix → Run queries in serving/phoenix/.
    - enriched user/device profiles via HBase/Phoenix.
- FastAPI service layer for features/profile lookup and model inference. → (optional) expose enriched data to external services.

### Search / Text Analytics
- Apache Solr: index curated documents, logs, or product catalogs; expose Solr SQL to BI or embed in FastAPI.

### Analytics / ML
- Notebooks (Jupyter) on Spark or Pandas. → exploratory data analysis and ML training.
- Spark MLlib + Python (scikit-learn, XGBoost, LightGBM) on curated Iceberg tables. (churn prediction, fraud detection.)
- MLflow for experiment tracking & model registry (nice add).

### Ops / Governance
- Apache Ranger (authz), Apache Atlas (lineage), OpenLineage → Airflow.
- Prometheus + Grafana for metrics.
- Hue (nice SQL UI).
- Ambari: optional—use for cluster-management practice; not essential today. => Ansible + Prometheus/Grafana

# Phase-to-Phase

## Phase 1 — Batch (RDBMS Batch Offloads)

### Goal: Postgres → curated data → query it.
Postgres → Kafka Connect JDBC (or Spark JDBC) → Kafka/Iceberg → Spark (ETL) → Iceberg refined
    - Ingest: Spark batch or Kafka Connect JDBC → raw Iceberg.
    - Transform: Spark SQL → refined & curated Iceberg.
    - Query: Trino / Hive / Impala + Superset.
    - Orchestrate with Airflow.
Nếu sử dụng Spark batch thì dùng thêm Airflow trigger
Deliverable: a DAG that lands orders/users/payments, builds daily partitions, and powers 2–3 
Superset charts.

## Phase 2 - Streaming data

### Goal: Log/click/IoT streaming into the lake. (File Drops / Logs)
- Generators → Kafka (KRaft).
    - python ingestion/generators/clickstream_gen.py
    - python ingestion/generators/iot_gen.py
- Schema Registry for events.
- Flows:
    - NiFi tail/HTTP → Kafka (preferred over Flume).
    - (Legacy sandbox: Logs → Flume → Kafka → HDFS.)
    - Kafka -> Flink parses and stores into /raw/logs/*.
- Persist streams to Iceberg (append-only) via Flink SQL or Spark Streaming.
- App/IoT Logs → (NiFi or Kafka SDK) → Kafka → Flink/Spark → Iceberg (raw/refined)
Deliverable: Kafka topics clicks, device_events; streaming sink to raw.events_* tables.
- If have 

## Phase 3 - Streaming processing
Scenarios
- Flink SQL: join clicks with device_profile (dimension in Iceberg or Kafka compacted topic) → enriched stream → Iceberg refined.clicks_enriched.
- Spark Streaming: fraud rule “>3 failed payments in 10 minutes per user” → emit fraud_alerts (Kafka + Iceberg).
- Batch Spark: build churn features daily → curated.user_features.
Deliverable: two running streaming jobs + one daily feature job.

## Phase 4 — Interactive analytics
- Hook Trino/Impala to Iceberg catalog.
- Build Superset dashboards over curated.* (funnel, LTV, fraud rate).
- Optional: Apache Drill lab to query disparate sources (HDFS, JDBC) ad-hoc—use as a learning playground rather than primary engine once Trino exists.
Deliverable: 3 dashboards + saved SQL queries.

## Phase 5 — Serving layer
- Pick HBase+Phoenix or Cassandra for online profiles & features.
    - Ingest curated features with Spark job → serving store.
    - Expose FastAPI for GET /features?user_id=....
- Cassandra:
    - Use cases: time-series events per user/device, idempotent upserts, geo-distributed reads.
    - Strengths: high write throughput, simple ops without HDFS/ZK.
- Optional: index enriched documents to Solr for search UI.
Deliverable: low-latency read < 20ms P95 for a few hot keys.

## Phase 6 — ML & ops hardening
- Train churn model on curated.user_features (Spark or Pandas). [Predict churn: train ML model on curated features (Spark MLlib + notebooks).]
- Log experiments in MLflow; export model to ONNX/PMML or pyfunc.
- Batch score to Iceberg; push top features to serving store.
- Add Ranger policies; set Atlas lineage; add Airflow OpenLineage emission.
Deliverable: nightly training + scoring DAG; simple A/B gates in FastAPI.

# Data Flows & Scenarios

## Postgres -> (CDC) -> Kakfa -> Iceberg
- Debezium (Kafka Connect) captures inserts/updates/deletes → topic per table.
- Flink SQL materializes CDC to Iceberg raw.postgres_*, compacts to hourly/daily snapshots.

## CDC dimension + streaming fact join (Flink)
- Postgres → Debezium → Kafka → (Schema Registry) → Flink/Spark → Iceberg (raw/refined)
- Postgres users via Debezium → Kafka compacted dim topic.
- Clickstream facts → Kafka.
- Flink temporal join → refined.clicks_enriched, sink both Iceberg + Kafka for real-time consumers.
- ideas:
    - Flink SQL consumes changes for enrichment or real-time joins.
    - Iceberg sink persists raw CDC events into /raw/postgres/*.
    - Optionally compact into daily snapshots in /refined/postgres/*.

## APIs/CRM → NiFi → Kafka/Iceberg
- NiFi: InvokeHTTP → JSON to Avro/Parquet → to Kafka (crm.customers, crm.contracts) or direct to Iceberg or HDFS via PutDatabaseRecord/PutParquet.
- Airflow DAG triggers NiFi flow nightly
- idea:
    - Spark SQL cleans the API dump and loads into /refined/crm/*
    - CRM API → NiFi → Kafka (or Iceberg raw) → Spark → Iceberg (refined)

## Logs/IoT → NiFi → Kafka → Flink → Iceberg
- NiFi tail/UDP/MQTT → Kafka.
- Flink: parse/enrich (GeoIP/device lookup) → refined.events_*.

## Curated build (batch)
- Spark SQL: Data Quality rules (null checks, type coercion), SCD2 for dims, feature tables for ML → curated.*.

## Serving sync
- Spark job writes curated.user_features → HBase (bulkload via HFiles) or Cassandra (DataStax/Spark connector).
- Phoenix view or Cassandra materialized views for read patterns.

## BI & SQL
- Trino catalog points at Iceberg + Hive Metastore; Superset connects to Trino.

## Search
- Spark job → Solr (SolrJ) with curated docs; use Solr SQL for ad-hoc.
    - Use cases: log search, product/doc search, autocomplete. Sits beside BI/serving; fed from curated datasets or streams.

## Fraud heuristics (Spark Streaming)
- Payments events from Kafka.
- Sliding window by user_id, count status='FAILED' > 3 in 10 min → emit fraud_alerts.
- Write alerts to Iceberg and to Cassandra/HBase; dashboard in Superset.

## Churn features (Spark batch)
- Aggregate last 30/60/90-day engagement, complaints, payment failures.
- Persist to curated.user_features (Iceberg).
- Train model (XGBoost/LightGBM) with MLflow tracking.
- Nightly score; serve churn_score via Phoenix/CQL + FastAPI.

## Search experience (Solr)
- Build product/doc index from curated.products with synonyms, facets.
- Expose /search?q=… via FastAPI → Solr.

# Note

- Nếu có CDC + BatchLoad:
    + Dùng CDC cho tables nhỏ, cập nhật thường xuyên. BatchLoad cho table to hoặc ít cập nhật
    + Sử dụng batch load cho việc backfilling nếu CDC bị overlap với batchload (filling missing partitions if CDC was down)
    + Có thể sử dụng cách merge + dedup (upsert)
    + Có thể dùng BatchLoad để đối chiếu với CDC (validation) => Kết quả có bằng nhau không => Nếu không => Backfil (Cách này dùng cho production, Real Systems)
    + Watermarking (add thêm cột load_type (CDC, Batch))
    + Boostrap (batchload 1 lần trong lúc start historical data) => sau đó disable và sử dụng CDC. Đối với các bảng tham chiếu nhỏ => Có thể không dùng CDC mà chỉ dùng batch load cũng được

# Data Flows

Postgres → Spark batch → Iceberg → Trino/Superset.
Kafka (KRaft) + NiFi → streams → Flink/Spark → Iceberg.
Realtime joins & fraud alerts.
Dashboards on curated.
Serving store (HBase+Phoenix or Cassandra) + FastAPI.
ML training/scoring + governance/lineage.
(Optional labs): Drill, Ambari, Storm, Flume, Sqoop in a separate sandbox.

# Note
- Schema-first: Enforce schemas in Kafka (SR) and Iceberg (evolution with constraints).
- Observability: Metrics (Prometheus), logs, lineage (Atlas/OpenLineage), data quality checks (Great Expectations or Deequ).
- Compaction: Flink/Spark writers should compact small files in Iceberg; set up maintenance DAGs.
- Security: Ranger policies (tables, columns, rows), secrets via Airflow connections/HashiCorp Vault.

# Old -> New Tool Mapping
- Sqoop -> Kafka Connect JDBC or Spark
- FLume -> Kafka Connect or NiFi
- Pig -> Spark SQL
- Oozie -> Airflow

Project layout:
/dags/                # Airflow DAGs
/jobs/spark/          # Spark batch & streaming
/jobs/flink/          # Flink SQL & pipelines
/nifi/flows/          # NiFi templates
/sql/                 # Trino/Hive/Impala queries
/schemas/             # Avro/JSON schemas
/models/              # ML notebooks + MLflow
/conf/                # Iceberg/Hive/Kafka configs

## OLTP Database

## Northwind database
- [Northwind](https://github.com/pthom/northwind_psql)

## Other Databases
- [AdventureWorks](https://github.com/chriseaton/docker-adventureworks)
- [DVD Rental](https://github.com/devrimgunduz/pagila)
- Sakila Movie Rental Store