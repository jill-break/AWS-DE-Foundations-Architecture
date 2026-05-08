# Hands-On Challenge: The Streaming Telemetry Project
An unconventional capstone project designed to evaluate architectural decision-making and practical implementation skills. Ideal as a selection tool for assessing technical readiness.

**Scenario**: A logistics company needs to capture live telemetry data (GPS coordinates, speed, vehicle ID) from thousands of delivery trucks. They want the raw data archived cheaply, but need the data highly optimized for future analytical queries by the BI team.

### Tasks:

**Data Generator**: Write a small Python script using the `boto3` library that generates fake JSON telemetry data and puts records continuously into an ingestion pipeline.

**Ingestion Layer**: Provision an *Amazon Kinesis Data Firehose delivery* stream. Document why Firehose was chosen over Kinesis Data Streams for this specific requirement.

**Format Optimization**: Configure Firehose to automatically convert the incoming JSON data into *Apache Parquet* format before delivery. (Requires defining an AWS Glue schema or utilizing an existing payload structure).

**Storage & Lifecycle**: Configure the destination *Amazon S3* bucket. Apply a lifecycle rule that transitions the Parquet files to S3 Standard-IA after 30 days, and to S3 Glacier Flexible Retrieval after 90 days.