# Lab 1.2: VPC and Network Setup

Architected a multi-tier, multi-AZ VPC that isolates data platform workloads from the public internet while enabling secure outbound access and private AWS service connectivity.

## What We Built

| Resource | ID / Value | Notes |
|---|---|---|
| VPC | `vpc-00e995395ecdadf02` | `data-platform-vpc`, 10.0.0.0/16 |
| Public Subnet (AZ1) | `subnet-0982cb6521c3b881c` | 10.0.1.0/24 — NAT Gateway lives here |
| Private Subnet 1A | `subnet-0e1b4e3913549ba5c` | 10.0.2.0/24 — compute / Glue |
| Private Subnet 1B | `subnet-02bbd74182a2450b0` | 10.0.3.0/24 — databases (RDS, Redshift) |
| Internet Gateway | `igw-016f1a6d101b231c2` | Outbound internet for public subnet |
| NAT Gateway | `nat-0aaaa8fb294c66af9` | Private subnets route outbound traffic here |
| Elastic IP | `100.50.129.50` | Attached to NAT Gateway |
| Public Route Table | `rtb-0168f81789233dbec` | 0.0.0.0/0 → IGW |
| Private Route Table | `rtb-05005c410c704071d` | 0.0.0.0/0 → NAT |
| SG: `data-sg-public-nat` | `sg-049136696578661e6` | NAT / bastion layer |
| SG: `data-sg-private-compute` | `sg-0312a93210d4c9909` | EC2, Glue, Lambda |
| SG: `data-sg-private-db` | `sg-0caec7dc95b8b77a9` | RDS, Redshift |
| S3 VPC Endpoint | `vpce-0826598df6834fb29` | S3 traffic stays on AWS backbone |
| DynamoDB VPC Endpoint | `vpce-082207865acf44b9b` | DynamoDB traffic stays on AWS backbone |
| Secrets Manager Endpoint | `vpce-0f1eceeca0db688ef` | Interface endpoint for Secrets Manager |

## Key Concepts

- **Public/private tier separation**: only the NAT Gateway sits in the public subnet; all workloads are private
- **VPC Endpoints (Gateway)**: S3 and DynamoDB traffic never leaves the AWS network — no NAT charges, no internet exposure
- **Secrets Manager Interface Endpoint**: private subnets can retrieve secrets without going via NAT
- **Security group naming**: prefixed `data-` because AWS rejects names starting with `sg`

## Infrastructure as Code

```
lab 2/IAC/terraform/
├── main.tf      — VPC, subnets, IGW, NAT, route tables, SGs, endpoints
├── variables.tf — aws_region, your_ip
└── outputs.tf   — VPC ID, subnet IDs, endpoint IDs
```

## Quick Start

```bash
cd "lab 2/IAC/terraform"
terraform init
terraform apply
```
