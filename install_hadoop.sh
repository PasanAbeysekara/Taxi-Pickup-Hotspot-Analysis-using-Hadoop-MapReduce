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