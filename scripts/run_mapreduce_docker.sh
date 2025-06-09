#!/bin/bash
set -e

DOCKER_COMPOSE_FILE="../docker-compose.yml" # Relative to scripts directory
HADOOP_ENV_FILE="../hadoop.env" # Relative to scripts directory
MAPREDUCE_JAR_PATH="../NYCTaxiAnalysis/target/NYCTaxiAnalysis-1.0-SNAPSHOT.jar"
LOCAL_INPUT_DIR="../data/input"
LOCAL_OUTPUT_DIR="../data/output_local"
MAPREDUCE_OUTPUT_FILE="$LOCAL_OUTPUT_DIR/mapreduce_output.txt"

HDFS_INPUT_DATA_DIR="/nyctaxi_input_data"
HDFS_LOOKUP_DIR="/nyctaxi_lookup_data"
HDFS_APP_DIR="/app"
HDFS_OUTPUT_DIR="/nyctaxi_output_data"

PARQUET_FILE_NAME="yellow_tripdata_2016-01.parquet"
LOOKUP_FILE_NAME="taxi_zone_lookup.csv"
JAR_FILE_NAME="NYCTaxiAnalysis-1.0-SNAPSHOT.jar"

# Ensure output directory exists locally
mkdir -p "$LOCAL_OUTPUT_DIR"
rm -f "$MAPREDUCE_OUTPUT_FILE" # Remove old output

echo "Starting Hadoop cluster via Docker Compose..."
(cd .. && sudo docker-compose -f docker-compose.yml --env-file hadoop.env up -d)

# Wait for Hadoop services to be ready (this is a simple wait, might need more robust checks)
echo "Waiting for Hadoop services to initialize (approx 90 seconds)..."
sleep 90 

echo "Checking Namenode health..."
# A more robust check would be to curl the JMX endpoint or a specific status page
if ! docker-compose -f ../docker-compose.yml exec namenode hdfs dfsadmin -report > /dev/null 2>&1; then
    echo "Namenode not healthy after wait. Exiting."
    (cd .. && sudo docker-compose -f docker-compose.yml down)
    exit 1
fi
echo "Namenode seems healthy."

echo "Preparing HDFS directories..."
docker-compose -f ../docker-compose.yml exec namenode hdfs dfs -mkdir -p "$HDFS_INPUT_DATA_DIR"
docker-compose -f ../docker-compose.yml exec namenode hdfs dfs -mkdir -p "$HDFS_LOOKUP_DIR"
docker-compose -f ../docker-compose.yml exec namenode hdfs dfs -mkdir -p "$HDFS_APP_DIR"
docker-compose -f ../docker-compose.yml exec namenode hdfs dfs -rm -r -f "$HDFS_OUTPUT_DIR" # Remove old HDFS output

echo "Uploading data and JAR to HDFS..."
# Note: The paths inside exec are relative to the container's FS, but docker cp/volumes handle mapping
# We've mounted local data to /data_local and jars to /app_jars in docker-compose.yml
docker-compose -f ../docker-compose.yml exec namenode hdfs dfs -put -f "/data_local/input/$PARQUET_FILE_NAME" "$HDFS_INPUT_DATA_DIR/"
docker-compose -f ../docker-compose.yml exec namenode hdfs dfs -put -f "/data_local/input/$LOOKUP_FILE_NAME" "$HDFS_LOOKUP_DIR/"
docker-compose -f ../docker-compose.yml exec namenode hdfs dfs -put -f "/app_jars/$JAR_FILE_NAME" "$HDFS_APP_DIR/"

echo "Running MapReduce job..."
# Assuming resourcemanager has hadoop client tools
docker-compose -f ../docker-compose.yml exec resourcemanager hadoop jar \
    "$HDFS_APP_DIR/$JAR_FILE_NAME" \
    com.nyctaxi.NYCTaxiDriver \
    "$HDFS_INPUT_DATA_DIR/$PARQUET_FILE_NAME" \
    "$HDFS_OUTPUT_DIR" \
    "$HDFS_LOOKUP_DIR/$LOOKUP_FILE_NAME"

echo "MapReduce job finished. Retrieving output..."
docker-compose -f ../docker-compose.yml exec namenode hdfs dfs -getmerge "$HDFS_OUTPUT_DIR/part-r-*" "/data_local/output_local/mapreduce_output.txt"

echo "Output saved to $MAPREDUCE_OUTPUT_FILE"

echo "Stopping Hadoop cluster..."
(cd .. && sudo docker-compose -f docker-compose.yml down)

echo "Local MapReduce execution complete."
