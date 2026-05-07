# CDEM2: Data Ingestion Pipelines

Built both batch and real-time ingestion pipelines on top of the S3 data lake: automated daily file transfers via DataSync, sub-second event streaming via Kinesis, and a capstone that converts streaming JSON to Parquet in flight using Firehose + Glue.

---

## Labs

### [Lab 1.3 — S3 Data Lake](lab%201/README.md)

Provisioned the central storage layer used by every downstream pipeline.

- Main bucket `data-lake-prod-352505432441` with versioning, SSE-S3, and access logging
- Logging bucket `data-lake-prod-logs-352505432441`
- Zone structure: `raw/` → `processed/` → `curated/` → `temp/` → `archive/`
- Lifecycle rules: auto-tier to Glacier / Deep Archive / deletion over time
- Bucket policy: `DenyNonHTTPS` + `DenyUnencryptedUploads`
- IaC: Terraform → `lab 1/IAC/terraform/`

### [Lab 2.2 — DataSync Batch Ingestion](lab%202/README.md)

Automated daily S3-to-S3 file ingestion on a schedule.

- Source bucket → `datasync-source-352505432441`
- DataSync task `batch-ingest-to-data-lake` → delivers to `data-lake-prod-352505432441/raw/`
- Schedule: `cron(0 2 * * ? *)` — every day at 2:00 AM UTC
- Files: `customer_master.csv`, `sales_history.csv`, `transaction_log.csv`
- IAM role `DataSyncS3Role` trusted by `datasync.amazonaws.com`
- IaC: Terraform → `lab 2/IAC/terraform/`

### [Lab 2.3 — Kinesis Real-Time Streaming](lab%203/README.md)

Built a sub-second event streaming pipeline with Python producer/consumer and durable S3 backup.

- Kinesis Data Stream `user-events-stream`: 4 shards, 24h retention
- Python producer: 5 events/second, 8 event types, partition key = `user_id`
- Python consumer: 4 parallel threads (one per shard), 1s poll interval
- Firehose `user-events-to-s3`: 5 MB / 300s buffer → GZIP → `streaming-data/` in data lake
- CloudWatch dashboard `kinesis-monitoring`: 4 metric widgets
- IaC: Terraform → `lab 3/IAC/terraform/`

### [Hands-On Challenge — Streaming Telemetry Pipeline](Hands-On%20Challenge/README.md)

Capstone: serverless end-to-end pipeline from JSON events → Parquet in S3, queryable via Athena.

- Python generator simulating 100 delivery trucks (GPS + speed telemetry)
- Kinesis Firehose with Record Format Conversion: JSON → Parquet using Glue schema
- 128 MB / 300s buffer prevents small-file syndrome
- S3 lifecycle: Standard → Standard-IA (30 days) → Glacier (90 days)
- **Score: 100/100**

---

## Key AWS Services

| Service | Used for |
|---|---|
| Amazon S3 | Central data lake storage, zone architecture |
| AWS DataSync | Scheduled batch file ingestion (S3-to-S3) |
| Amazon Kinesis Data Streams | Real-time event ingestion, ordered per partition key |
| Amazon Kinesis Firehose | Durable delivery to S3; format conversion to Parquet |
| AWS Glue Data Catalog | Schema registry for Parquet conversion |
| Amazon CloudWatch | Stream metrics and monitoring dashboard |
| Terraform | IaC for all three labs |

---

## Ingestion Patterns Covered

| Pattern | Latency | Throughput | Cost model | Best for |
|---|---|---|---|---|
| DataSync (batch) | Minutes–hours | Files | Per GB transferred | Daily file drops, bulk migration |
| Kinesis Streams (real-time) | < 1 second | 1,000 records/s per shard | Per shard-hour | Sub-second event pipelines |
| Firehose (micro-batch) | 60–900 seconds | Unlimited (serverless) | Per GB ingested | Write-once delivery to S3 |
