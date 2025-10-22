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

# Format HDFS NameNode
$HADOOP_HOME/bin/hdfs namenode -format -force -nonInteractive
clean_folder_dir $HADOOP_DATA_DIR/nameNode

# Format NameNode (only if no metadata exists yet)
if [ ! -f "$HADOOP_DATA_DIR/nameNode/current/VERSION" ]; then
    echo "Formatting NameNode..."
    $HADOOP_HOME/bin/hdfs namenode -format -force -nonInteractive
else
    echo "NameNode already formatted. Skipping format."
fi

# Start NameNode
echo "Starting HDFS NameNode..."
# $HADOOP_HOME/sbin/hadoop-daemon.sh start namenode # old style, 2.x Hadoop
$HADOOP_HOME/bin/hdfs --daemon start namenode

# Start ResourceManager & MapReduceJobHistoryServer if used
if [ "$HDFS_ONLY" != "true" ]; then
    # Start ResourceManager
    echo "Starting YARN ResourceManager..."
    # $HADOOP_HOME/sbin/yarn-daemon.sh start resourcemanager # old style, 2.x Hadoop
    $HADOOP_HOME/bin/yarn --daemon start resourcemanager

    # Start MapReduceJobHistoryServer
    echo "Starting MapReduce JobHistory Server..."
    # $HADOOP_HOME/sbin/mr-jobhistory-daemon.sh start historyserver # old style, 2.x Hadoop
    $HADOOP_HOME/bin/mapred --daemon start historyserver
else
    echo "HDFS_ONLY is true — skipping YARN ResourceManager & MapReduceJobHistoryServer startup."
fi

# Keep container alive (if running inside Docker)
tail -f /dev/null
