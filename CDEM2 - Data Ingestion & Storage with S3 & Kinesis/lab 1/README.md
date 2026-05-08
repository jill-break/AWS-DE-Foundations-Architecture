# Lab 1.3 (CDEM2 Lab 1): S3 Data Lake

Provisioned the central S3 data lake with encryption, versioning, access logging, lifecycle policies, and a security-enforcing bucket policy.

## What We Built

| Resource | Name | Notes |
|---|---|---|
| Main bucket | `data-lake-prod-352505432441` | Primary data lake storage |
| Logging bucket | `data-lake-prod-logs-352505432441` | Receives S3 access logs from main bucket |
| Folder structure | `raw/`, `processed/`, `curated/`, `temp/`, `archive/` | Logical separation of data zones |
| Versioning | Enabled on main bucket | Protects against accidental overwrites |
| Encryption | SSE-S3 (AES256) on both buckets | Default encryption enforced |
| Lifecycle: `processed/` | → Glacier after 90 days → Deep Archive after 180 days | Cost-optimized long-term storage |
| Lifecycle: `temp/` | Deleted after 1 day | Automatic cleanup |
| Lifecycle: `archive/` | → Glacier after 1 day → Deep Archive after 91 days → Deleted after 7 years | Full retention lifecycle |
| Bucket policy | `DenyNonHTTPS` + `DenyUnencryptedUploads` | Enforces TLS and SSE on all uploads |

## Key Concepts

- **Zone architecture**: raw → processed → curated mirrors ETL pipeline stages
- **Defense-in-depth**: bucket policy blocks unencrypted uploads as a second layer after SSE default
- **Lifecycle rules**: data automatically moves to cheaper storage tiers as it ages — up to 95% cost reduction over time
- **Access logging**: all S3 API calls recorded to the logs bucket for audit and compliance

## Infrastructure as Code

```
lab 1/IAC/terraform/
├── main.tf      — both buckets, versioning, encryption, public access block,
│                  access logging, lifecycle rules, bucket policy, folder objects
├── variables.tf — aws_region
└── outputs.tf   — bucket names and ARNs
```

## Quick Start

```bash
cd "lab 1/IAC/terraform"
terraform init
terraform apply
```

> **Teardown**: `terraform destroy` — bucket must be empty first, or set `force_destroy = true`
