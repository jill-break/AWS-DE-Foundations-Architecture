# AWS Data Engineering Foundations — CDEM01

End-to-end AWS data engineering course (Phase 2). Each module builds on the last: secure networking → ingestion pipelines → analytics warehouse. Every lab is backed by Terraform IaC; every hands-on challenge scored 100/100.

---

## Course Map

| Module | Focus | Labs | Challenge |
|---|---|---|---|
| [CDEM1](CDEM1/README.md) | Secure Architecture & Networking | IAM, VPC | Secure Data Landing Zone |
| [CDEM2](CDEM2/README.md) | Data Ingestion Pipelines | S3 Data Lake, DataSync, Kinesis | Streaming Telemetry Pipeline |
| [CDEM3](CDEM3/README.md) | Redshift Analytics | Cluster Setup, COPY + Spectrum, Table Design | — |

---

## CDEM1: Secure Architecture and Core Networking

> Foundation: every downstream service runs inside this security perimeter.

### Lab 1.1 — IAM Setup ([lab 1/](CDEM1/lab%201/README.md))
Five least-privilege IAM roles (`DataEngineerRole`, `GlueServiceRole`, `LambdaExecutionRole`, `RedshiftIAMRole`, `AnalystReadOnlyRole`) and two custom policies enforcing SSE encryption on S3 uploads.

### Lab 1.2 — VPC and Network Setup ([lab 2/](CDEM1/lab%202/README.md))
Multi-tier, multi-AZ VPC (`data-platform-vpc`, 10.0.0.0/16): public subnet for NAT Gateway, private subnets for compute and databases, VPC Endpoints for S3/DynamoDB/Secrets Manager so AWS-service traffic never traverses the internet.

### Hands-On Challenge — Secure Data Landing Zone ([challenge/](CDEM1/Hands-On%20Challenge%20The%20Secure%20Data%20Landing%20Zone/README.md))
CloudFormation-provisioned healthcare data landing zone. Zero-Trust networking (S3 accessible only via VPC Endpoint), SSM-only EC2 access (no SSH keys), RDS credentials in Secrets Manager, AWS Backup daily vault. RPO: 5 min, RTO: < 2 min. **Score: 100/100.**

---

## CDEM2: Data Ingestion Pipelines

> Layer 2: getting data into the lake via batch and real-time pipelines.

### Lab 1.3 — S3 Data Lake ([lab 1/](CDEM2/lab%201/README.md))
Central data lake bucket with versioning, AES256 encryption, access logging, a 5-zone folder structure (`raw/` → `processed/` → `curated/` → `temp/` → `archive/`), lifecycle policies (Glacier / Deep Archive / delete), and a bucket policy enforcing HTTPS and encryption on all uploads.

### Lab 2.2 — DataSync Batch Ingestion ([lab 2/](CDEM2/lab%202/README.md))
Scheduled S3-to-S3 DataSync task (`cron(0 2 * * ? *)`) copying `customer_master.csv`, `sales_history.csv`, and `transaction_log.csv` from a source bucket into `data-lake-prod-*/raw/` nightly.

### Lab 2.3 — Kinesis Real-Time Streaming ([lab 3/](CDEM2/lab%203/README.md))
4-shard Kinesis Data Stream (`user-events-stream`) with a Python producer (~5 events/s, 8 event types), a parallel 4-thread Python consumer, Kinesis Firehose backing up to S3 as GZIP JSON (5 MB / 300s buffer), and a CloudWatch monitoring dashboard. End-to-end latency: < 1 second.

### Hands-On Challenge — Streaming Telemetry Pipeline ([challenge/](CDEM2/Hands-On%20Challenge/README.md))
Serverless ETL: Python generator → Kinesis Firehose → Glue Schema → Apache Parquet → S3 with lifecycle tiering (Standard → Standard-IA → Glacier). No servers, no ETL jobs, data queryable in Athena within 5 minutes of generation. **Score: 100/100.**

---

## CDEM3: Redshift Analytics

> Layer 3: turning raw S3 data into fast analytical queries.

### Lab 3.1 — Redshift Cluster Setup ([lab 1/](CDEM3/lab%201/README.md))
Two-node `ra3.xlplus` Redshift cluster in the private data-platform VPC: KMS encryption, Secrets Manager password management, IP-restricted security group, CloudWatch audit logging. Cost: ~$0.96/hour.

### Lab 3.2 — COPY Command + Redshift Spectrum ([lab 2/](CDEM3/lab%202/README.md))
Bulk-loaded three tables from S3 via COPY (`customers`, `orders`, `events`). Queried the same data externally via Redshift Spectrum (`events_external`) using a Glue Data Catalog schema — demonstrating the hot-data (COPY) vs cold-data (Spectrum) trade-off.

### Lab 3.3 — Table Design Optimization ([lab 3/](CDEM3/lab%203/README.md))
Redesigned all three tables: DISTKEY on join columns for co-located joins (zero redistribution), SORTKEY on date/time columns for block pruning, COMPOUND SORTKEY for multi-column filtering, per-column compression (RAW / DELTA / ZSTD / LZO). Result: 70–80% storage reduction, 5–10× query improvement (up to 100× at scale).

---

## Infrastructure as Code Summary

All labs use Terraform (AWS provider v5). Key patterns:

| Pattern | Detail |
|---|---|
| S3 object uploads | `server_side_encryption = "AES256"` on all objects (bucket policy enforces it) |
| Redshift passwords | `manage_master_password = true` — stored in Secrets Manager, never in state |
| Redshift logging | Separate `aws_redshift_logging` resource (inline block deprecated in provider v5) |
| Node type | `ra3.xlplus` — dc2.large is retired in new AWS accounts |
| VPC lookup | Hardcoded `id = "vpc-016a46803312b4334"` — duplicate tag in account prevented data source lookup |
| DataSync encryption | `DataSyncS3Role` excluded from `DenyUnencryptedUploads` — DataSync uses bucket default encryption |

---

## AWS Account

**Account ID**: `352505432441` | **Region**: `us-east-1`
