#!/bin/bash

# Exit on any error
set -e

echo "Starting Hadoop Installation Script..."

# Update package list
echo "Updating package list..."
sudo apt-get update

# Install Java
echo "Installing OpenJDK..."
sudo apt-get install -y openjdk-8-jdk

# Install Maven and Python3
echo "Installing Maven and Python3..."
sudo apt-get install -y maven python3 python3-pip wget

# Create Hadoop user
echo "Creating hadoop user..."
sudo adduser hadoop --gecos "Hadoop User,,,," --disabled-password
echo "hadoop:hadoop" | sudo chpasswd
sudo usermod -aG sudo hadoop

# Install SSH
echo "Installing SSH..."
sudo apt-get install -y openssh-server openssh-client

# Generate SSH keys
echo "Generating SSH keys..."
sudo -u hadoop ssh-keygen -t rsa -P "" -f /home/hadoop/.ssh/id_rsa
sudo -u hadoop cat /home/hadoop/.ssh/id_rsa.pub >> /home/hadoop/.ssh/authorized_keys
sudo -u hadoop chmod 0600 /home/hadoop/.ssh/authorized_keys

# Download and install Hadoop
echo "Downloading Hadoop..."
wget https://downloads.apache.org/hadoop/common/hadoop-3.3.6/hadoop-3.3.6.tar.gz
tar xzf hadoop-3.3.6.tar.gz
sudo mv hadoop-3.3.6 /usr/local/hadoop
sudo chown -R hadoop:hadoop /usr/local/hadoop

# Set environment variables
echo "Setting up environment variables..."
echo '
# Hadoop Environment Variables
export HADOOP_HOME=/usr/local/hadoop
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin
export HADOOP_MAPRED_HOME=$HADOOP_HOME
export HADOOP_COMMON_HOME=$HADOOP_HOME
export HADOOP_HDFS_HOME=$HADOOP_HOME
export YARN_HOME=$HADOOP_HOME
' | sudo tee -a /home/hadoop/.bashrc

# Configure Hadoop
echo "Configuring Hadoop..."
sudo -u hadoop bash -c 'cat > /usr/local/hadoop/etc/hadoop/core-site.xml << EOL
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://localhost:9000</value>
    </property>
</configuration>
EOL'

sudo -u hadoop bash -c 'cat > /usr/local/hadoop/etc/hadoop/hdfs-site.xml << EOL
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
    <property>
        <name>dfs.replication</name>
        <value>1</value>
    </property>
    <property>
        <name>dfs.namenode.name.dir</name>
        <value>/usr/local/hadoop/data/namenode</value>
    </property>
    <property>
        <name>dfs.datanode.data.dir</name>
        <value>/usr/local/hadoop/data/datanode</value>
    </property>
</configuration>
EOL'

# Create Hadoop data directories
echo "Creating Hadoop directories..."
sudo -u hadoop mkdir -p /usr/local/hadoop/data/namenode
sudo -u hadoop mkdir -p /usr/local/hadoop/data/datanode

# Format HDFS
echo "Formatting HDFS..."
sudo -u hadoop /usr/local/hadoop/bin/hdfs namenode -format

# Start Hadoop
echo "Starting Hadoop services..."
sudo -u hadoop start-dfs.sh
sudo -u hadoop start-yarn.sh

# Create project structure
echo "Setting up project structure..."
mkdir -p NYCTaxiAnalysis/{src/main/java/com/nyctaxi,data,scripts,target}

# Download dataset to the correct location
echo "Downloading NYC Taxi dataset..."
cd NYCTaxiAnalysis/data
wget -O yellow_tripdata_2016-01.parquet https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2016-01.parquet
wget -O taxi_zone_lookup.csv https://raw.githubusercontent.com/PasanAbeysekara/Taxi-Pickup-Hotspot-Analysis-using-Hadoop-MapReduce/main/data/taxi_zone_lookup.csv

# Create HDFS directories and upload data
echo "Creating HDFS directories and uploading data..."
hdfs dfs -mkdir -p /user/hadoop/nyctaxi_input
hdfs dfs -mkdir -p /user/hadoop/nyctaxi_lookup
hdfs dfs -put yellow_tripdata_2016-01.parquet /user/hadoop/nyctaxi_input/
hdfs dfs -put taxi_zone_lookup.csv /user/hadoop/nyctaxi_lookup/
cd ..

# Download Python script
echo "Downloading Python analysis script..."
cd scripts
wget -O get_top_n.py https://raw.githubusercontent.com/PasanAbeysekara/Taxi-Pickup-Hotspot-Analysis-using-Hadoop-MapReduce/main/scripts/get_top_n.py
cd ..

# Build and run MapReduce job
echo "Building MapReduce job..."
mvn clean package

echo "Running MapReduce job..."
hadoop jar target/NYCTaxiAnalysis-1.0-SNAPSHOT.jar com.nyctaxi.NYCTaxiDriver \
/user/hadoop/nyctaxi_input/yellow_tripdata_2016-01.parquet \
/user/hadoop/nyctaxi_output \
/user/hadoop/nyctaxi_lookup/taxi_zone_lookup.csv

# Get results
echo "Retrieving results..."
hdfs dfs -getmerge /user/hadoop/nyctaxi_output/part-r-* local_output.txt

# Run Python analysis
echo "Running Python analysis..."
python3 scripts/get_top_n.py local_output.txt

echo "Installation and analysis completed!"
echo "You can find the results in local_output.txt"
