# 🚕 Taxi Pickup Hotspot Analysis using Hadoop MapReduce

## 📁 Assignment Title

Large-Scale Data Analysis Using MapReduce

## 🎯 Objective

This project implements a custom Hadoop MapReduce job to analyze one month of NYC Yellow Taxi trip data (January 2016) and extract meaningful insights about the busiest pickup zones.

---

## 👥 Team Members

- Member 1: [Your Name]
- Member 2: [Your Name]
- Member 3: [Your Name]

---

## 1. 📊 Dataset

We used a publicly available dataset provided by NYC Taxi and Limousine Commission:

- **Dataset**: [yellow_tripdata_2016-01.parquet](https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2016-01.parquet)
- **Description**: Yellow taxi trip records for January 2016
- **Format**: Parquet

Converted to CSV using `parquet-tools` for ease of use with Hadoop streaming jobs.

---

## 2. 🛠️ Implemented MapReduce Task

**Task**: Find the busiest taxi pickup locations based on pickup counts.

**Steps**:

- Extract pickup location IDs
- Count frequency using a MapReduce job
- Map location IDs to zone names using a lookup table

---

## 3. ⚙️ Environment Setup

- **System**: Local Ubuntu 22.04
- **Hadoop**: Version 3.x installed locally
- **Parquet Tools**: For format conversion

**Evidence of Installation**:

> 📸 _[Insert screenshot of Hadoop running here]_  
> _Screenshot: Hadoop Namenode UI or terminal with running job_

---

## 4. 🧪 Testing & Execution

**Steps to Run**:

```bash
# Convert Parquet to CSV
parquet-tools csv yellow_tripdata_2016-01.parquet > yellow_tripdata_2016-01.csv

# Extract pickup_location_id
cut -d ',' -f8 yellow_tripdata_2016-01.csv > pickup_locations.txt

# Start HDFS
hdfs namenode -format
start-dfs.sh

# Put file to HDFS
hdfs dfs -mkdir /taxidata
hdfs dfs -put pickup_locations.txt /taxidata

# Run MapReduce Job
hadoop jar $HADOOP_HOME/share/hadoop/tools/lib/hadoop-streaming-*.jar \
-input /taxidata/pickup_locations.txt \
-output /taxidata/output \
-mapper mapper.py \
-reducer reducer.py

# Get output
hdfs dfs -cat /taxidata/output/part-00000 > output.txt
```
