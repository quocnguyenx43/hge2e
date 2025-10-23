## High-Level Architecture

### Orchestration:
- Airflow: DAGs for batch ETL, CDC backfills, ML pipelines, Housekeeping.

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





IDEAs
==========================================
┌─────────────────────────────────────────────────────────────────┐
│                        DATA SOURCES                              │
├─────────────────────────────────────────────────────────────────┤
│ • PostgreSQL (OLTP): orders, users, payments, products          │
│ • MySQL (OLTP): inventory, suppliers                            │
│ • APIs: CRM, Banking, Weather                                   │
│ • Generators: Clickstream, IoT sensors, Application logs        │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                    INGESTION LAYER                               │
├─────────────────────────────────────────────────────────────────┤
│ BATCH:                                                           │
│ • NiFi → Primary ETL orchestrator (replaces Sqoop/Flume)       │
│ • Kafka Connect → CDC from databases                            │
│                                                                  │
│ STREAMING:                                                       │
│ • Kafka (KRaft mode) → Central event bus                        │
│ • Schema Registry → Avro/Protobuf schemas                       │
│ • Kafka Streams → Lightweight transformations                   │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                    STORAGE LAYER                                 │
├─────────────────────────────────────────────────────────────────┤
│ HDFS (Data Lake):                                               │
│ • /raw/              → Raw dumps (Parquet, Avro, JSON)         │
│ • /cleansed/         → Validated, deduplicated                  │
│ • /processed/        → Transformed, enriched                    │
│ • /curated/          → Analytics-ready star schemas             │
│                                                                  │
│ Cassandra:                                                       │
│ • Time-series data (IoT, metrics)                               │
│ • User activity logs                                            │
│                                                                  │
│ HBase:                                                          │
│ • Real-time feature store                                       │
│ • User/device profiles                                          │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                  PROCESSING LAYER                                │
├─────────────────────────────────────────────────────────────────┤
│ BATCH:                                                           │
│ • Spark SQL → ETL jobs (replaces Pig)                          │
│ • Spark MLlib → ML training (replaces Mahout)                  │
│ • Hive → SQL-based transformations                              │
│                                                                  │
│ STREAMING:                                                       │
│ • Flink SQL → Stream joins, aggregations                        │
│ • Spark Structured Streaming → Fraud detection                  │
│ • Kafka Streams → Real-time enrichment                          │
│                                                                  │
│ ORCHESTRATION:                                                   │
│ • Airflow → Workflow scheduling (replaces Oozie)               │
│ • Airflow DAGs for end-to-end pipelines                         │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                   WAREHOUSE LAYER                                │
├─────────────────────────────────────────────────────────────────┤
│ • Hive → Batch SQL over HDFS (managed tables)                  │
│ • Presto/Trino → Interactive queries across sources             │
│ • Impala → Low-latency SQL on HDFS                             │
│ • Apache Drill → Schema-free SQL (JSON, Parquet, MongoDB)     │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                    SERVING LAYER                                 │
├─────────────────────────────────────────────────────────────────┤
│ • HBase + Phoenix → Real-time lookups via SQL                  │
│ • Cassandra → Time-series queries                               │
│ • Solr → Full-text search (product catalog, logs)             │
│ • Redis → Caching layer for hot data                            │
│ • FastAPI/Flask → REST APIs for applications                    │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│               ANALYTICS & VISUALIZATION                          │
├─────────────────────────────────────────────────────────────────┤
│ • Jupyter/Zeppelin → Exploratory data analysis                 │
│ • Apache Superset → BI dashboards                               │
│ • Grafana → Real-time monitoring dashboards                     │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                 MANAGEMENT & MONITORING                          │
├─────────────────────────────────────────────────────────────────┤
│ • Ambari → Cluster management & provisioning                    │
│ • Prometheus + Grafana → Metrics monitoring                     │
│ • ELK Stack → Log aggregation                                   │
│ • YARN → Resource management                                    │
│ • Ranger → Security & access control                            │
└─────────────────────────────────────────────────────────────────┘

🚀 Phase-by-Phase Implementation Roadmap
Phase 1: Foundation - Batch Ingestion Pipeline
Goal: Move structured data from PostgreSQL → HDFS
Components:

PostgreSQL with sample e-commerce schema (users, orders, products, payments)
NiFi flow: GetJDBCConnection → ConvertRecord → PutHDFS
HDFS zones created: /datalake/raw/postgres/
Hive external tables pointing to HDFS raw data
Airflow DAG to schedule daily NiFi job

Scenario:
-- Sample data in PostgreSQL
CREATE TABLE orders (
  order_id SERIAL PRIMARY KEY,
  user_id INT,
  product_id INT,
  amount DECIMAL,
  order_date TIMESTAMP
);

Validation Query:
sql-- In Hive
SELECT COUNT(*), MIN(order_date), MAX(order_date) 
FROM raw.orders;

Phase 2: Streaming Ingestion
Goal: Ingest real-time clickstream + IoT data
Components:

Python generators producing JSON events:

    Clickstream: {user_id, page_url, timestamp, session_id}
    IoT: {device_id, temperature, location, timestamp}


Kafka topics: clickstream, iot-sensors
NiFi processors: ConsumeKafka → PutHDFS (raw JSON files)
Schema Registry to validate Avro schemas

Data Flow:
Generator → Kafka Topic → NiFi → HDFS (/raw/streaming/)
                        ↘ Kafka Streams (optional filtering)

Phase 3: Data Cleansing & Transformation
Goal: Clean raw data → processed zone

Old Way (Learning Purpose):

    Write a Pig script to clean /raw/products/
        Remove nulls, deduplicate, join with categories
        Output to /processed/products_clean/

Modern Way:

    Spark SQL job (PySpark):

        pythondf_raw = spark.read.parquet("/datalake/raw/postgres/products")
        df_clean = df_raw.dropDuplicates(["product_id"]) \
                        .filter(col("price") > 0) \
                        .withColumn("category", upper(col("category")))
        df_clean.write.parquet("/datalake/processed/products")
    Airflow DAG:
        pythonraw_to_processed = SparkSubmitOperator(
            task_id='clean_products',
            application='/jobs/clean_products.py'
        )

Phase 4: Real-Time Stream Processing
Goal: Join streaming data with batch data
Scenario 1: Flink SQL
    sql-- Join clickstream with user dimension table
    CREATE TABLE enriched_clicks AS
    SELECT 
    c.user_id,
    u.name,
    u.country,
    c.page_url,
    c.timestamp
    FROM clickstream c
    JOIN users FOR SYSTEM_TIME AS OF c.timestamp AS u
    ON c.user_id = u.user_id;
Scenario 2: Spark Streaming Fraud Detection
    python# Detect users with >3 failed payments in 5 min window
    payments = spark.readStream.format("kafka") \
                    .option("subscribe", "payments") \
                    .load()

    fraud_alerts = payments \
        .groupBy(window("timestamp", "5 minutes"), "user_id") \
        .agg(count(when(col("status") == "failed", 1)).alias("failures")) \
        .filter(col("failures") > 3)

    fraud_alerts.writeStream \
        .format("parquet") \
        .option("path", "/datalake/curated/fraud_alerts") \
        .start()

Phase 5: Data Warehousing
Goal: Create analytics-ready star schemas
Hive Tables:
sql-- Fact table
CREATE TABLE curated.fact_orders (
  order_id BIGINT,
  user_id INT,
  product_id INT,
  amount DECIMAL,
  order_date DATE
) PARTITIONED BY (year INT, month INT)
STORED AS PARQUET;

-- Dimension tables
CREATE TABLE curated.dim_users (...);
CREATE TABLE curated.dim_products (...);
Query with Presto:
sql-- Cross-database query
SELECT 
  p.product_name,
  SUM(o.amount) as revenue
FROM hive.curated.fact_orders o
JOIN hive.curated.dim_products p 
  ON o.product_id = p.product_id
WHERE o.year = 2025
GROUP BY p.product_name
ORDER BY revenue DESC
LIMIT 10;
Apache Drill Use Case:
sql-- Query JSON files directly without schema
SELECT customer.name, orders[0].total
FROM dfs.`/datalake/raw/streaming/clickstream/*.json`
WHERE customer.country = 'Vietnam';


Phase 6: Serving Layer
Goal: Real-time lookups for applications
HBase Schema:
Table: user_profiles
Row Key: user_id
Column Families:
  - info: name, email, country
  - activity: last_login, total_orders
  - features: churn_score, lifetime_value
Phoenix SQL:
sqlCREATE VIEW user_profiles (
  pk VARCHAR PRIMARY KEY,
  info.name VARCHAR,
  features.churn_score DOUBLE
);

-- Query via JDBC
SELECT name, churn_score 
FROM user_profiles 
WHERE churn_score > 0.7;
Cassandra for Time-Series:
sqlCREATE TABLE iot_readings (
  device_id UUID,
  timestamp TIMESTAMP,
  temperature DOUBLE,
  PRIMARY KEY (device_id, timestamp)
) WITH CLUSTERING ORDER BY (timestamp DESC);
Solr for Search:
bash# Index product catalog
curl http://solr:8983/solr/products/update?commit=true \
  -d '[{"id":"P1001","name":"Laptop","category":"Electronics"}]'

# Full-text search
curl "http://solr:8983/solr/products/select?q=name:Laptop"

Phase 7: Machine Learning
Goal: Train churn prediction model
Feature Engineering (Spark):
python# Aggregate user behavior features
features = spark.sql("""
  SELECT 
    user_id,
    COUNT(order_id) as order_count,
    AVG(amount) as avg_order_value,
    DATEDIFF(current_date, MAX(order_date)) as days_since_last_order,
    churn_label
  FROM curated.fact_orders o
  JOIN curated.dim_users u ON o.user_id = u.user_id
  GROUP BY user_id, churn_label
""")
Model Training (Spark MLlib):
pythonfrom pyspark.ml.classification import RandomForestClassifier
from pyspark.ml.feature import VectorAssembler

assembler = VectorAssembler(
    inputCols=["order_count", "avg_order_value", "days_since_last_order"],
    outputCol="features"
)
rf = RandomForestClassifier(labelCol="churn_label")

pipeline = Pipeline(stages=[assembler, rf])
model = pipeline.fit(features)

# Save predictions to HBase
predictions.write.format("org.apache.phoenix.spark") \
          .options(table="user_profiles", zkUrl="zookeeper:2181") \
          .save()

🎬 End-to-End Scenarios
Scenario 1: E-Commerce Order Analytics

Ingest: NiFi pulls orders from PostgreSQL → HDFS /raw/
Transform: Spark job joins orders + users + products → /curated/
Warehouse: Hive table partitioned by date
Query: Presto dashboard showing daily revenue by category
Serve: HBase stores top customers for recommendation engine

Scenario 2: Real-Time Fraud Detection

Stream: Payment events → Kafka
Process: Spark Streaming detects >3 failures in 5 min
Alert: Write fraud cases to HBase
Dashboard: Grafana shows fraud metrics from Prometheus

Scenario 3: IoT Sensor Analytics

Ingest: IoT devices → Kafka → NiFi → Cassandra (time-series)
Batch: Spark job aggregates daily stats → HDFS
Query: Drill analyzes raw JSON + Cassandra in one query
Search: Solr indexes anomaly logs for troubleshooting

📂 Data Lake Zones
/datalake/
├── raw/
│   ├── postgres/          # NiFi dumps from PostgreSQL
│   ├── mysql/             # NiFi dumps from MySQL
│   ├── streaming/
│   │   ├── clickstream/   # Kafka → NiFi JSON files
│   │   └── iot/           # IoT sensor data
│   └── api/               # External API responses
├── cleansed/
│   ├── deduplicated/      # Remove duplicates
│   └── validated/         # Schema validation passed
├── processed/
│   ├── enriched/          # Joined with dimensions
│   └── aggregated/        # Pre-computed metrics
└── curated/
    ├── star_schema/       # Fact/dimension tables
    └── ml_features/       # Training datasets


🛠️ Airflow DAG Example
pythonfrom airflow import DAG
from airflow.providers.apache.spark.operators.spark_submit import SparkSubmitOperator
from airflow.providers.apache.hive.operators.hive import HiveOperator

with DAG('daily_etl_pipeline', schedule_interval='@daily') as dag:
    
    # Step 1: Ingest from PostgreSQL
    ingest = BashOperator(
        task_id='nifi_trigger',
        bash_command='curl http://nifi:8080/start-flow'
    )
    
    # Step 2: Clean raw data
    clean = SparkSubmitOperator(
        task_id='spark_clean',
        application='/jobs/clean_raw_data.py'
    )
    
    # Step 3: Build star schema
    transform = HiveOperator(
        task_id='hive_transform',
        hql='INSERT INTO curated.fact_orders SELECT ...'
    )
    
    # Step 4: Update HBase
    serve = SparkSubmitOperator(
        task_id='update_hbase',
        application='/jobs/write_to_hbase.py'
    )
    
    ingest >> clean >> transform >> serve

🚦 Getting Started Steps

Week 1-2: Setup Hadoop cluster (HDFS, YARN, Ambari)
Week 3: PostgreSQL → NiFi → HDFS → Hive (first vertical slice)
Week 4: Add Kafka + generators → streaming ingestion
Week 5: Spark jobs for cleansing (raw → processed)
Week 6: Flink SQL for stream joins
Week 7: HBase + Phoenix for real-time serving
Week 8: Cassandra for time-series data
Week 9: Solr for search, Drill for schema-free queries
Week 10: ML with Spark MLlib
Week 11: Airflow orchestration + Superset dashboards
Week 12: Add monitoring (Prometheus, Grafana, Ranger)


## 💎 Where Each Tool Fits

| Tool           | Layer          | Use Case                                          |
|----------------|----------------|--------------------------------------------------|
| **NiFi**       | Ingestion       | Drag-and-drop ETL, replaces Sqoop/Flume          |
| **Kafka**      | Ingestion       | Event streaming backbone                         |
| **Kafka Connect** | Ingestion    | CDC from databases                               |
| **HDFS**       | Storage         | Data lake (raw/processed/curated zones)          |
| **Cassandra**  | Storage         | Time-series data (IoT, logs)                     |
| **HBase**      | Serving         | Real-time feature store                          |
| **Spark**      | Processing      | Batch ETL, ML training (replaces Pig/Mahout)     |
| **Flink**      | Processing      | Stream joins, windowed aggregations              |
| **Hive**       | Warehouse       | Batch SQL over HDFS                              |
| **Presto/Trino** | Warehouse     | Interactive cross-source queries                 |
| **Impala**     | Warehouse       | Low-latency SQL on HDFS                          |
| **Drill**      | Warehouse       | Schema-free SQL over JSON/NoSQL                  |
| **Phoenix**    | Serving         | SQL interface for HBase                          |
| **Solr**       | Serving         | Full-text search                                 |
| **Airflow**    | Orchestration   | Workflow scheduling (replaces Oozie)             |
| **Ambari**     | Management      | Cluster provisioning & monitoring                |
| **Superset**   | Analytics       | BI dashboards                                   |

Streaming events:
orders.new
orders.status
customers.new
order_items.new
Store in a staging table (Postgres or ClickHouse)
Update revenue counters in Redis or Elasticsearch
Emit alerts (e.g., “High-value order > $1,000”)

Writes rolling aggregates to ClickHouse (for BI dashboards)
Sends alerts to Slack if total sales > threshold
Fraud / Risk Detection
