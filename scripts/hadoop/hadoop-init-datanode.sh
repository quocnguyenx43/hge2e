#!/bin/bash

source /scripts/hadoop-utils.sh

# Format HDFS DataNode
clean_data_inside_folder $HADOOP_DATA_DIR/dataNode

# Start HDFS DataNode
echo "Starting HDFS DataNode..."
$HADOOP_HOME/bin/hdfs --daemon start datanode

# Start NodeManager if used
if [ "$HDFS_ONLY" != "true" ]; then
    echo "Starting YARN NodeManager..."
    $HADOOP_HOME/bin/yarn --daemon start nodemanager
else
    echo "HDFS_ONLY is true — skipping YARN NodeManager startup."
fi

# Keep container alive (if running inside Docker)
tail -f /dev/null
