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