#!/bin/bash

source /scripts/hadoop-utils.sh

# Format HDFS NameNode
$HADOOP_HOME/bin/hdfs namenode -format -force -nonInteractive
clean_data_inside_folder $HADOOP_DATA_DIR/nameNode

# Format HDFS NameNode (only if no metadata exists yet)
if [ ! -f "$HADOOP_DATA_DIR/nameNode/current/VERSION" ]; then
    echo "Formatting NameNode..."
    $HADOOP_HOME/bin/hdfs namenode -format -force -nonInteractive
else
    echo "NameNode already formatted. Skipping format."
fi

# Start NameNode
echo "Starting HDFS NameNode..."
$HADOOP_HOME/bin/hdfs --daemon start namenode

# Start YARN ResourceManager & MapReduceJobHistoryServer if used
if [ "$HDFS_ONLY" != "true" ]; then
    # Start ResourceManager
    echo "Starting YARN ResourceManager..."
    $HADOOP_HOME/bin/yarn --daemon start resourcemanager

    # Start MapReduceJobHistoryServer
    echo "Starting MapReduce JobHistory Server..."
    $HADOOP_HOME/bin/mapred --daemon start historyserver
else
    echo "HDFS_ONLY is true — skipping YARN ResourceManager & MapReduceJobHistoryServer startup."
fi

# Keep container alive (if running inside Docker)
tail -f /dev/null
