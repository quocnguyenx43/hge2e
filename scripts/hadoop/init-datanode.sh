#!/bin/bash

HADOOP_HOME=/opt/hadoop
HADOOP_DATA_DIR=/data/dfs

clean_folder_dir() {
    local NODE_DIR="$1"

    if [ -z "$NODE_DIR" ]; then
        echo "Error: No directory path provided in 'clean_folder_dir'."
        return 1
    fi

    if [ -d "$NODE_DIR" ]; then
        rm -rf "${NODE_DIR:?}/"*
        chown -R hadoop:hadoop "$NODE_DIR"
        chmod 755 "$NODE_DIR"
        echo "Node directory cleaned and permissions reset."
    else
        echo "Node folder does not exist: $NODE_DIR"
    fi
}

# Format HDFS DataNode
clean_folder_dir $HADOOP_DATA_DIR/dataNode

# Start DataNode
echo "Starting HDFS DataNode..."
# $HADOOP_HOME/sbin/hadoop-daemon.sh start datanode # old style, 2.x Hadoop
$HADOOP_HOME/bin/hdfs --daemon start datanode

# Start NodeManager if used
if [ "$HDFS_ONLY" != "true" ]; then
    echo "Starting YARN NodeManager..."
    # $HADOOP_HOME/sbin/yarn-daemon.sh start nodemanager # old style, 2.x Hadoop
    $HADOOP_HOME/bin/yarn --daemon start nodemanager
else
    echo "HDFS_ONLY is true — skipping YARN NodeManager startup."
fi

# Keep container alive (if running inside Docker)
tail -f /dev/null
