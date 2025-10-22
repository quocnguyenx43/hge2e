#!/bin/bash
# Script to run Sqoop imports
# From PostgreSQL to HDFS

# Connections
POSTGRES_CONNECTION="jdbc:postgresql://${POSTGRES_HOST}:${POSTGRES_PORT}/${POSTGRES_DB}"
POSTGRES_USER="${POSTGRES_USER}"
POSTGRES_PASS="${POSTGRES_PASS}"
HDFS_URI="${HDFS_URI}"

# 1. Test connection to Postgres
echo "Checking PostgreSQL connection..."
if ! sqoop eval \
    --connect "${POSTGRES_CONNECTION}" \
    --driver org.postgresql.Driver \
    --username "${POSTGRES_USER}" \
    --password "${POSTGRES_PASS}" \
    --query 'SELECT 1;' >/dev/null; then
    echo "Connection to Postgres: Failed!"
    exit 1
fi
echo "Connection to Postgres: OK"

# 2. Test connection to ResourceManager
echo "Checking YARN ResourceManager connection..."
if ! curl -s "http://namenode:8088/ws/v1/cluster/info" | grep -q '"state":"STARTED"'; then
    echo "Connection to ResourceManager: Failed!"
    exit 1
fi
echo "Connection to ResourceManager: OK"

# 3. Test HDFS is alive
echo "Checking HDFS connection..."
if ! hdfs dfs -ls "${HDFS_URI}/" >/dev/null 2>&1; then
    echo "HDFS connection: Failed!"
    exit 1
fi
echo "HDFS connection: OK"

# 4. Importing tables
TABLES=(
    "customers"
    "customer_activity"
    "device_events"
    "employees"
    "employee_territories"
    "categories"
    "orders"
    "order_details"
    "region"
    "shippers"
    "suppliers"
    "territories"
    "us_states"
)
FAILED_TABLES=()

for TABLE in "${TABLES[@]}"; do
    echo "Importing table: $TABLE"

    if ! sqoop import \
        --connect "${POSTGRES_CONNECTION}" \
        --username "${POSTGRES_USER}" \
        --password "${POSTGRES_PASS}" \
        --driver org.postgresql.Driver \
        --table "${TABLE}" \
        --target-dir "${HDFS_URI}/datalake/raw/${TABLE}" \
        --delete-target-dir \
	--as-textfile \
        --num-mappers 1; then
        echo "Import failed for table: ${TABLE}"
        FAILED_TABLES+=("${TABLE}")
        continue
    fi

    echo "Successfully imported: ${TABLE}"
done

# 5. Final status
if [ ${#FAILED_TABLES[@]} -ne 0 ]; then
    echo "The following tables failed to import: ${FAILED_TABLES[*]}"
    exit 1
else
    echo "All tables imported successfully!"
fi
