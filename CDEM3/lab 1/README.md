# Lab 3.1: Redshift Cluster Setup

Provisioned a production-grade Amazon Redshift cluster in the existing data-platform VPC, with KMS encryption, Secrets Manager password management, IP-restricted access, and CloudWatch audit logging.

## What We Built

| Resource | Name / Value | Notes |
|---|---|---|
| Redshift cluster | `redshift-tier3-lab` | Database: `analytics` |
| Node type | `ra3.xlplus` | dc2.large retired in new AWS accounts |
| Node count | 2 | Multi-node for parallel query execution |
| Master user | `awsadmin` | Password managed by AWS Secrets Manager |
| Encryption | Enabled | KMS key: `42e4c9a1-3ffd-43b1-9e2e-0ae1d74fde73` |
| VPC | `vpc-016a46803312b4334` | data-platform-vpc (hardcoded — duplicate tag in account) |
| Subnet group | `redshift-tier3-subnet-group` | Private subnets 10.0.2.0/24 + 10.0.3.0/24 |
| Security group | `redshift-security-group` | Port 5439 inbound from `196.61.35.158/32` only |
| IAM role | `RedshiftIAMRole` | Attached to cluster for COPY commands |
| Audit logging | CloudWatch | `userlog`, `connectionlog`, `useractivitylog` |
| Backup retention | 2 days | Automated snapshots |

## Key Concepts

- **ra3.xlplus**: managed storage node type — compute and storage scale independently; use instead of dc2 in new accounts
- **Secrets Manager integration**: `manage_master_password = true` rotates and stores the password without it ever appearing in Terraform state
- **IP-restricted SG**: only your IP can reach port 5439 — no public access
- **`aws_redshift_logging` resource**: the inline `logging {}` block was deprecated in AWS provider v5; use the separate resource instead

## Infrastructure as Code

```
lab 1/IAC/terraform/
├── main.tf      — VPC lookup, KMS key data source, IAM role, SG, subnet group,
│                  cluster (manage_master_password), CloudWatch logging resource
├── variables.tf — aws_region, your_ip
└── outputs.tf   — cluster endpoint, identifier, database, port, ARN, secret ARN
```

## Quick Start

```bash
cd "lab 1/IAC/terraform"
terraform init
terraform apply   # prompted for your_ip (e.g. 1.2.3.4)
```

> **Teardown**: `terraform destroy` — stops ~$0.96/hour in charges
