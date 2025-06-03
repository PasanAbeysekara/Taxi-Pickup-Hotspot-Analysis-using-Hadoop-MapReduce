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
![2](https://github.com/user-attachments/assets/61441a13-bc29-4065-9825-5e78f4dd6154)
![3](https://github.com/user-attachments/assets/e59bf819-0912-4ca7-8612-5060e5648db9)
![4](https://github.com/user-attachments/assets/e645108b-cf2c-4fed-9726-656e5bf25807)
![5](https://github.com/user-attachments/assets/04045a98-3883-4b76-9750-25aca509c212)
![6](https://github.com/user-attachments/assets/25202d5e-d805-4812-9e54-a2ed5b270061)
![7](https://github.com/user-attachments/assets/7ca10f0f-d2fc-4356-bd3a-7d0a5ec2b0cb)
![8](https://github.com/user-attachments/assets/5c6d5321-69fd-47aa-ae42-049088b5d48c)

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
## 5. 📌 Interpretation of Results
We observed that the busiest zones were primarily concentrated in Manhattan, with Midtown and the Upper East Side topping the list. This aligns with expectations due to the commercial and residential density in these areas.

Performance Observations:

Efficient on local Hadoop setup for 100,000+ rows

Quick map and reduce stages due to data simplicity

Expansion Suggestions:

Analyze by hour or day

Combine with weather data

Visualize using plotting tools


![9](https://github.com/user-attachments/assets/3f4ddf45-c52e-4bb3-8d99-7dd691b4aeec)
![10](https://github.com/user-attachments/assets/39850884-6bed-4c97-8583-015687bbfb34)
![11](https://github.com/user-attachments/assets/9cb60892-80a6-4fb1-9311-f80912bb699a)
![12](https://github.com/user-attachments/assets/2b93dc8b-74dc-4504-86d5-78aae36a2dd5)
![13](https://github.com/user-attachments/assets/320794ca-1d64-4cbc-969a-061caa7e77ca)
![14](https://github.com/user-attachments/assets/2709493f-7c43-484a-9804-27bd1e967e3f)
![15](https://github.com/user-attachments/assets/2ceca7fa-9b15-4c30-96ad-a865920d23a7)
![16](https://github.com/user-attachments/assets/10b72413-8ead-495d-8584-2142ae58a35e)
![17](https://github.com/user-attachments/assets/7400c138-dd1a-489e-bbab-77c9e18da467)
![18](https://github.com/user-attachments/assets/d10867ff-64dd-4a14-88b9-06b97eb1c51c)
![19](https://github.com/user-attachments/assets/066d01fc-ce83-459f-aebc-48faec398276)
![20](https://github.com/user-attachments/assets/838f9953-27cc-4f5c-9e9d-582192568c4f)
![21](https://github.com/user-attachments/assets/6cfe2723-32b8-49b0-a878-36969a317407)

Screenshot: Evidence of output
