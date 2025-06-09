#!/bin/bash
set -e

echo "Starting SSHD service..."
service ssh start

# Format HDFS NameNode if not already formatted
if [ ! -d "$HADOOP_HOME/data/namenode/current" ]; then
  echo "Formatting HDFS NameNode..."
  hdfs namenode -format -force -nonInteractive
fi

echo "Starting Hadoop services..."
start-dfs.sh
start-yarn.sh
# Keep container running or execute passed command
exec "$@"
