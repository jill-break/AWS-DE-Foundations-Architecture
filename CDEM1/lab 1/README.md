# Lab 1.1: IAM Setup

Established the identity foundation for the entire data platform by creating least-privilege IAM roles and custom security policies.

## What We Built

| Resource | Name | Purpose |
|---|---|---|
| IAM Role | `DataEngineerRole` | Daily work role — S3, Glue, Redshift, EMR, Kinesis, Lambda, CloudWatch |
| IAM Role | `GlueServiceRole` | Used by Glue jobs — S3, CloudWatch Logs, Secrets Manager |
| IAM Role | `LambdaExecutionRole` | Used by Lambda functions — S3, DynamoDB, Kinesis, CloudWatch Logs |
| IAM Role | `RedshiftIAMRole` | Used by Redshift COPY commands — S3, CloudWatch Logs |
| IAM Role | `AnalystReadOnlyRole` | Read-only analyst access — Redshift, Athena, QuickSight, S3 |
| Custom Policy | `DataLakeBucketAccessPolicy` | Restricts S3 access to data-lake buckets; blocks unencrypted uploads |
| Custom Policy | `QuickSightReadOnlyPolicy` | Allows analysts to view dashboards without edit rights |

## Key Concepts

- **Principle of Least Privilege**: each role has only the permissions its service needs and nothing more
- **Separation of duties**: engineers, analysts, Glue, Lambda, and Redshift all have distinct roles
- **Encryption enforcement**: `DataLakeBucketAccessPolicy` denies `s3:PutObject` unless `s3:x-amz-server-side-encryption` is present

## Infrastructure as Code

```
lab 1/IAC/terraform/
├── main.tf      — all 5 IAM roles + 2 custom policies
├── variables.tf — aws_region
└── outputs.tf   — role ARNs
```

## Quick Start

```bash
cd "lab 1/IAC/terraform"
terraform init
terraform apply
```
