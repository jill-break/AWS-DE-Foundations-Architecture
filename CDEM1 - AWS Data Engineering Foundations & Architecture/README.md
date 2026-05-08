# CDEM1: Secure Architecture and Core Networking

Established the security and networking foundation that every subsequent module builds on: least-privilege IAM roles, a multi-tier VPC, and a capstone challenge that combined both into a fully IaC-provisioned healthcare data landing zone.

---

## Labs

### [Lab 1.1 — IAM Setup](lab%201/README.md)

Created the identity layer for the entire data platform.

- 5 IAM roles: `DataEngineerRole`, `GlueServiceRole`, `LambdaExecutionRole`, `RedshiftIAMRole`, `AnalystReadOnlyRole`
- 2 custom policies: `DataLakeBucketAccessPolicy` (enforces SSE), `QuickSightReadOnlyPolicy`
- IaC: Terraform → `lab 1/IAC/terraform/`

### [Lab 1.2 — VPC and Network Setup](lab%202/README.md)

Architected the network isolation layer used by all data workloads.

- Custom VPC `data-platform-vpc` (10.0.0.0/16) across 2 AZs
- Public subnet (NAT) + 2 private subnets (compute + databases)
- NAT Gateway, 3 Security Groups, VPC Endpoints for S3 / DynamoDB / Secrets Manager
- IaC: Terraform → `lab 2/IAC/terraform/`

### [Hands-On Challenge — Secure Data Landing Zone](Hands-On%20Challenge%20The%20Secure%20Data%20Landing%20Zone/README.md)

Capstone project combining IAM + VPC into a production-grade healthcare data landing zone.

- CloudFormation IaC: VPC, subnets, S3 (SSE-S3), VPC Endpoint, EC2 role (SSM-only access)
- Zero-Trust networking: S3 bucket policy allows access only via VPC Endpoint
- No SSH keys: EC2 access via SSM Session Manager only
- RDS credentials: AWS Secrets Manager (never hardcoded)
- Disaster Recovery Plan: RPO 5 min, RTO < 2 min (Multi-AZ RDS), AWS Backup daily vault
- **Score: 100/100**

---

## Key AWS Services

| Service | Used for |
|---|---|
| IAM | Roles, custom policies, least-privilege access |
| VPC | Network isolation, public/private tiers |
| NAT Gateway | Outbound internet for private subnets |
| VPC Endpoints | Private S3/DynamoDB/Secrets Manager access |
| AWS Secrets Manager | RDS credential storage |
| AWS Backup | Automated daily backups with retention |
| CloudFormation | IaC for the capstone challenge |
| Terraform | IaC for Labs 1.1 and 1.2 |

---

## Guiding Principles

- **Principle of Least Privilege**: every role has exactly the permissions it needs and nothing more
- **Zero Trust Networking**: no resource is trusted by default; access is explicitly granted per path
- **Infrastructure as Code**: all resources defined in version-controlled templates — no console click-ops
- **Encryption everywhere**: SSE-S3 on all buckets, KMS available, Secrets Manager for credentials
