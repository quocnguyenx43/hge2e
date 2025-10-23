#!/bin/bash

HADOOP_HOME=/opt/hadoop
HADOOP_DATA_DIR=/data/dfs

clean_data_inside_folder() {
    local NODE_DIR="$1"

    if [ -z "$NODE_DIR" ]; then
        echo "Error: No directory path provided in 'clean_data_inside_folder'."
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
