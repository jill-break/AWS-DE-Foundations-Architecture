# Hands-On Challenge: Secure Data Landing Zone

Designed and provisioned a fully hardened, zero-trust data landing zone for a healthcare analytics team migrating to AWS. All infrastructure is defined in CloudFormation IaC. No hardcoded credentials. No public-facing attack surface. **Score: 100/100.**

---

## Architecture

```
                    Internet
                       │
                  [Internet Gateway]
                       │
         ┌─────────────────────────────┐
         │         Public Subnet        │  ← NAT Gateway only
         │   (outbound traffic only)    │    no inbound from internet
         └──────────────┬──────────────┘
                        │ (NAT — OS patches only)
         ┌──────────────┴──────────────┐
         │  Private Subnet (AZ1)        │  ← EC2 Processing Node
         │  Private Subnet (AZ2)        │  ← RDS Standby (Multi-AZ)
         │                              │
         │  [S3 Gateway Endpoint]       │  ← S3 traffic stays on AWS backbone
         │  [SSM Interface Endpoint]    │  ← Admin access via SSM (no SSH)
         └─────────────────────────────┘
                        │
                  [RawDataBucket]
                (S3, SSE-AES256, VPC-only policy)
```

---

## What We Built

| Resource | Service | Key Configuration |
|---|---|---|
| Custom VPC | VPC | 2 AZs, public + private subnets |
| NAT Gateway | EC2 | Outbound-only; no inbound from internet |
| S3 Raw Data Bucket | S3 | SSE-S3 (AES256), accessible only via VPC Endpoint |
| S3 Gateway Endpoint | VPC Endpoint | S3 traffic never leaves AWS network |
| SSM Interface Endpoint | VPC Endpoint | Admin EC2 access via SSM, no SSH port open |
| EC2 Processing Node | EC2 | Private subnet; no public IP; no SSH keys |
| EC2 IAM Instance Profile | IAM | Scoped to `RawDataBucket` ARN only |
| RDS PostgreSQL (Multi-AZ) | RDS | Primary AZ1 + synchronous standby AZ2 |
| RDS Security Group | SG | Inbound only from EC2 security group |
| RDS Credentials | Secrets Manager | Dynamically generated, never hardcoded |
| AWS Backup Vault | AWS Backup | `HealthcareVault`, daily plan, 30-day retention |
| Backup Plan | AWS Backup | `HealthcareDailyBackup`, tag `Backup-Policy: Healthcare-Daily` |

---

## Security Layers

### 1. Zero-Trust Network Topology
- Private subnets have no route to the Internet Gateway — they are invisible to the public internet
- NAT Gateway exists only for outbound OS updates; no inbound traffic is permitted
- All AWS service traffic (S3, SSM) routes through private VPC Endpoints — bypasses NAT, no internet exposure

### 2. Identity-Centric Access (no SSH keys, no hardcoded credentials)
- EC2 uses an **IAM Instance Profile** (temporary credentials via STS) — no access keys on disk
- Admin access via **SSM Session Manager** over a private interface endpoint — Port 22 is never opened
- RDS credentials stored in **AWS Secrets Manager** — application retrieves them at runtime

### 3. Encryption Everywhere
- S3: SSE-S3 (AES-256) default encryption
- RDS: encryption at rest
- All service-to-service communication forced over HTTPS (TLS 1.2+)
- Bucket policy explicitly denies any request not originating from the VPC Endpoint

### 4. Micro-Segmentation
- RDS Security Group: accepts connections **only** from the EC2 Security Group on the DB port — nothing else in the VPC can reach the database

---

## Disaster Recovery Plan

### Recovery Objectives

| Resource | RPO | RTO | Mechanism |
|---|---|---|---|
| RDS (AZ failure) | 0 | < 2 min | Multi-AZ automatic failover (synchronous replication) |
| RDS (data corruption) | 5 min | < 30 min | Point-in-Time Recovery (PITR) |
| S3 (deletion/ransomware) | 24 hours | Variable | AWS Backup restore from `HealthcareVault` |

### Incident Response

**Scenario A — S3 data deletion or ransomware:**
1. Identify the incident timestamp
2. AWS Backup console → Protected Resources → select recovery point before incident
3. Restore in-place (overwrite) or to an isolated bucket for forensics

**Scenario B — RDS data corruption:**
1. Identify the corruption timestamp
2. RDS console → Restore to point in time → provision new instance
3. Update Secrets Manager endpoint reference → decommission corrupted instance

**Scenario C — Full AZ failure:**
1. RDS: automatic Multi-AZ failover, same connection string, no action needed
2. EC2: provision new instance in secondary private subnet using `landing-zone.yaml`

### AWS Backup Configuration
- **Plan**: `HealthcareDailyBackup` — daily snapshots of all resources tagged `Backup-Policy: Healthcare-Daily`
- **Vault**: `HealthcareVault` — encrypted; supports **Vault Lock** (WORM) for ransomware protection
- **Retention**: 30 days

---

## Infrastructure as Code

```
Hands-On Challenge The Secure Data Landing Zone/
├── IAC/
│   └── landing-zone.yaml  — CloudFormation: VPC, subnets, IGW, NAT, SGs, route tables,
│                             S3 bucket + policy, S3 gateway endpoint, SSM interface
│                             endpoint, EC2 role + instance profile, RDS Multi-AZ,
│                             Secrets Manager secret, AWS Backup vault + plan
├── Architecture Diagram/
│   ├── Architecture.png    — Visual topology diagram
│   └── Readme.md           — Detailed architecture rationale (zero-trust, SSM, Spectrum)
├── Assessment Report.md    — Evaluator's 100/100 score and comments
└── Disaster Recovery Plan.md — Full DR plan (RPO/RTO, incident response procedures)
```

## Deploy

```bash
aws cloudformation deploy \
  --template-file IAC/landing-zone.yaml \
  --stack-name secure-data-landing-zone \
  --capabilities CAPABILITY_NAMED_IAM
```
