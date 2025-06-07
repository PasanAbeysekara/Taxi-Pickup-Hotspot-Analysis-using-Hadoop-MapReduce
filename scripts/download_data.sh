#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status.

DATA_INPUT_DIR="../data/input"
PARQUET_URL="https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2016-01.parquet"
LOOKUP_URL="https://s3.amazonaws.com/nyc-tlc/misc/taxi_zone_lookup.csv" # Example URL, find official if possible

PARQUET_FILE="$DATA_INPUT_DIR/yellow_tripdata_2016-01.parquet"
LOOKUP_FILE="$DATA_INPUT_DIR/taxi_zone_lookup.csv"

echo "Creating data directory if it doesn't exist..."
mkdir -p "$DATA_INPUT_DIR"

echo "Downloading Parquet data..."
if [ ! -f "$PARQUET_FILE" ]; then
    wget -O "$PARQUET_FILE" "$PARQUET_URL"
else
    echo "Parquet file already exists."
fi

echo "Downloading lookup CSV..."
if [ ! -f "$LOOKUP_FILE" ]; then
    wget -O "$LOOKUP_FILE" "$LOOKUP_URL"
else
    echo "Lookup CSV file already exists."
fi

echo "Data download complete."
