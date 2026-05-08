# Hands-On Challenge: Streaming Telemetry Pipeline

Designed and implemented a production-grade streaming ETL pipeline that ingests GPS telemetry from 100 simulated delivery trucks, converts it to optimized Parquet format in flight, and stores it in a cost-tiered S3 data lake — all without any servers.

## Architecture

```
Python Script (boto3)
  └─► Kinesis Data Firehose
         └─► [Glue Schema → Parquet conversion]
                └─► S3 Data Lake
                       ├─ Standard (0–30 days)
                       ├─ Standard-IA (30–90 days)
                       └─ Glacier (90+ days)
```

## What We Built

| Component | Service | Key Decision |
|---|---|---|
| Data generation | Python + boto3 | JSONLines format (`\n`) for human-readable recovery |
| Schema governance | AWS Glue Data Catalog | Manual schema definition with strict types (`double` for GPS) |
| Ingestion engine | Kinesis Data Firehose | Serverless; no shard management |
| Format conversion | Firehose → Parquet | Columnar format reduces Athena scan costs |
| Buffer | 128 MB / 300 seconds | Prevents "small file syndrome" |
| Storage | S3 with Lifecycle Rules | 3-tier cost optimization |

## Data Schema (telemetry events)

- `vehicle_id` — string
- `timestamp` — string (ISO-8601)
- `lat` / `long` — double (GPS precision)
- `speed` — double (km/h)

## Data Lifecycle

| Time | Event |
|---|---|
| T=0s | Truck sends JSON via Python script |
| T=1s | Firehose receives and buffers the record |
| T=300s | Firehose converts buffer to Parquet and writes to S3 |
| T=301s | Data immediately queryable via Amazon Athena |
| T=30 days | Data moves to Standard-IA (cheaper) |
| T=90 days | Data moves to Glacier (archival) |

## Key Concepts

- **Parquet over JSON**: columnar storage means Athena scans only the columns in your SELECT — 10–100× cheaper for wide tables
- **Firehose vs Kinesis Data Streams**: Firehose is fully serverless (no shards to manage), better for write-once ETL to S3
- **Record Format Conversion**: Firehose transforms JSON → Parquet using the Glue schema at flush time — no ETL job needed
- **Small File problem**: small S3 files hurt Athena performance; a 128 MB buffer ensures each file is large enough to be efficient

## Files

```
Hands-On Challenge/
├── generator.py    — Python producer simulating 100 delivery trucks
├── decisions.txt   — design rationale and architectural choices
├── summery.md      — project summary and key takeaways
├── Todo.md         — challenge task checklist
└── screenshots/    — S3 bucket, Glue DB, Firehose, Parquet output
```

## Assessment: 100/100
