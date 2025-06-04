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
