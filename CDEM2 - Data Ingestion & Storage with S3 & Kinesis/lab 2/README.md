# Lab 2.2: DataSync Batch Ingestion

Automated daily batch ingestion of CSV files from a source S3 bucket into the data lake using AWS DataSync, with a scheduled task running at 2:00 AM UTC.

## What We Built

| Resource | Name / Value | Notes |
|---|---|---|
| Source bucket | `datasync-source-352505432441` | Encrypted (SSE-S3), public access blocked |
| DataSync location (source) | S3 → `datasync-source-352505432441` | |
| DataSync location (dest) | S3 → `data-lake-prod-352505432441/raw/` | |
| DataSync task | `batch-ingest-to-data-lake` | Scheduled: `cron(0 2 * * ? *)` |
| IAM role | `DataSyncS3Role` | Trusted by `datasync.amazonaws.com` |

## Data Files Transferred

| File | Contents |
|---|---|
| `customer_master.csv` | Customer profiles — ID, name, email, phone, address, signup date |
| `sales_history.csv` | Sales transactions — sale ID, customer ID, amount, date, category |
| `transaction_log.csv` | Payment records — transaction ID, sale ID, method, status, timestamp |

## Key Concepts

- **S3-to-S3 DataSync**: no agent required for cloud-to-cloud transfers
- **Overwrite mode `ALWAYS`**: destination stays in sync with source changes
- **Preserve deleted `REMOVE`**: files deleted at source are deleted at destination
- **Encryption exception**: `DenyUnencryptedUploads` bucket policy excludes `DataSyncS3Role` because DataSync relies on bucket default encryption and does not send the SSE header

## Infrastructure as Code

```
lab 2/IAC/terraform/
├── main.tf      — source bucket, IAM role + policy, DataSync source/dest locations,
│                  DataSync task with schedule
├── variables.tf — aws_region
└── outputs.tf   — task ARN, location ARNs, IAM role ARN, source bucket name
```

## Quick Start

```bash
cd "lab 2/IAC/terraform"
terraform init
terraform apply
```

To trigger a manual run immediately after apply:

```bash
aws datasync start-task-execution \
  --task-arn $(terraform output -raw task_arn)
```
