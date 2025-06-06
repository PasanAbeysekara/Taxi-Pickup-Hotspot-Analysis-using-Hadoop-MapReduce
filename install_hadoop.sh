#!/bin/bash

set -e

echo "========== STEP 1: Install Dependencies =========="
sudo apt-get update
sudo apt-get install -y openjdk-11-jdk maven ssh rsync wget

echo "========== STEP 2: Set Environment Variables =========="
JAVA_HOME=$(dirname $(dirname $(readlink -f $(which javac))))
echo "export JAVA_HOME=$JAVA_HOME" >> ~/.bashrc
echo "export PATH=\$PATH:\$JAVA_HOME/bin" >> ~/.bashrc
source ~/.bashrc

echo "========== STEP 3: Download and Configure Hadoop =========="
HADOOP_VERSION=3.4.1
HADOOP_DIR=$HOME/hadoop
HADOOP_HOME=$HADOOP_DIR/hadoop-${HADOOP_VERSION}

mkdir -p "$HADOOP_DIR"
cd "$HADOOP_DIR"

if [ ! -f "hadoop-${HADOOP_VERSION}.tar.gz" ]; then
  wget "https://dlcdn.apache.org/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz"
fi

if [ ! -d "$HADOOP_HOME" ]; then
  tar -xzf "hadoop-${HADOOP_VERSION}.tar.gz"
fi

echo "export HADOOP_HOME=$HADOOP_HOME" >> ~/.bashrc
echo "export PATH=\$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin" >> ~/.bashrc
echo "export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop" >> ~/.bashrc
source ~/.bashrc

echo "========== STEP 4: Configure Hadoop Core Files =========="
cd "$HADOOP_HOME/etc/hadoop"

cat > core-site.xml <<EOF
<configuration>
  <property>
    <name>fs.defaultFS</name>
    <value>hdfs://localhost:9000</value>
  </property>
</configuration>
EOF

cat > hdfs-site.xml <<EOF
<configuration>
  <property>
    <name>dfs.replication</name>
    <value>1</value>
  </property>
</configuration>
EOF

# Only copy template if it exists
if [ -f mapred-site.xml.template ]; then
  cp mapred-site.xml.template mapred-site.xml
fi

cat > mapred-site.xml <<EOF
<configuration>
  <property>
    <name>mapreduce.framework.name</name>
    <value>yarn</value>
  </property>
</configuration>
EOF

cat > yarn-site.xml <<EOF
<configuration>
  <property>
    <name>yarn.nodemanager.aux-services</name>
    <value>mapreduce_shuffle</value>
  </property>
</configuration>
EOF

# Fix JAVA_HOME path in Hadoop config
sed -i "s|^# export JAVA_HOME=.*|export JAVA_HOME=$JAVA_HOME|" hadoop-env.sh

echo "========== STEP 5: Format HDFS =========="
$HADOOP_HOME/bin/hdfs namenode -format -force

echo "========== STEP 6: Start Hadoop Services =========="
$HADOOP_HOME/sbin/start-dfs.sh
$HADOOP_HOME/sbin/start-yarn.sh

echo "========== STEP 7: Clone NYC Taxi Project =========="
cd ~
rm -rf Taxi-Pickup-Hotspot-Analysis-using-Hadoop-MapReduce
git clone https://github.com/PasanAbeysekara/Taxi-Pickup-Hotspot-Analysis-using-Hadoop-MapReduce.git

echo "========== STEP 8: Download Dataset =========="
cd Taxi-Pickup-Hotspot-Analysis-using-Hadoop-MapReduce/NYCTaxiAnalysis
mkdir -p data
cd data
wget -nc https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2016-01.parquet
wget -nc https://d37ci6vzurychx.cloudfront.net/misc/taxi_zone_lookup.csv
cd ..

echo "========== STEP 9: Build with Maven =========="
mvn clean package

echo "========== STEP 10: Upload Files to HDFS =========="
HDFS_INPUT="/user/$(whoami)/nyctaxi_input"
HDFS_LOOKUP="/user/$(whoami)/nyctaxi_lookup"
HDFS_OUTPUT="/user/$(whoami)/nyctaxi_output"

hdfs dfs -mkdir -p "$HDFS_INPUT"
hdfs dfs -mkdir -p "$HDFS_LOOKUP"
hdfs dfs -put -f data/yellow_tripdata_2016-01.parquet "$HDFS_INPUT/"
hdfs dfs -put -f data/taxi_zone_lookup.csv "$HDFS_LOOKUP/"
hdfs dfs -rm -r -f "$HDFS_OUTPUT" || true

echo "========== STEP 11: Run MapReduce Job =========="
hadoop jar target/NYCTaxiAnalysis-1.0-SNAPSHOT.jar com.nyctaxi.NYCTaxiDriver \
"$HDFS_INPUT/yellow_tripdata_2016-01.parquet" \
"$HDFS_OUTPUT" \
"$HDFS_LOOKUP/taxi_zone_lookup.csv"

echo "========== STEP 12: Display Top 10 Zones =========="
hdfs dfs -get "$HDFS_OUTPUT/part-r-00000" result.txt
sort -k2 -nr result.txt | head -n 10

echo "✅ DONE: NYC Taxi Hotspot Analysis Completed."
