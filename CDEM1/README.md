# AWS Data Engineering Foundations - Secure Architecture

This repository holds documentation and instructions for building a secure, scalable data engineering platform on AWS. The exercises focus heavily on securing cloud infrastructure by applying the Principle of Least Privilege (IAM), establishing isolated multi-tier networks (VPC), and defining comprehensive disaster recovery protocols.

## Implemented Components

### 1. Identity and Access Management (Lab 1)
**Directory**: `lab 1/`  
**Status**: Completed
- **Role Structuring**: Configured 5 distinct IAM roles (`DataEngineerRole`, `GlueServiceRole`, `LambdaExecutionRole`, `RedshiftIAMRole`, `AnalystReadOnlyRole`) tailored rigidly to their necessary scopes, minimizing blast radius and access bloat.
- **Custom Security Policy**: Developed `DataLakeBucketAccessPolicy` to strictly regulate data lake access and enforce AES256 server-side encryption, blocking any unencrypted uploads.

### 2. VPC, Subnets & Network Setup (Lab 2)
**Directory**: `lab 2/`  
**Status**: Completed
- **VPC Configuration**: Architected `data-platform-vpc` (10.0.0.0/16) securely segmented into distinct public and private subnets across multiple Availability Zones to ensure high availability and robust security.
- **Subnet Layering**: 
  - **Public Subnet**: Acts as the "lobby" containing the NAT Gateway.
  - **Private Subnets**: Completely severed from inbound internet access. Hosts RDS databases and compute instances (EC2, Lambda, Glue).
- **VPC Endpoints**: Implemented Gateway endopoints for S3 and DynamoDB to route traffic cleanly inside the AWS network, dramatically reducing costs and surface exposure.

### 3. Secure Data Landing Zone Challenge
**Directory**: `Hands-On Challenge The Secure Data Landing Zone/`  
**Status**: Completed
- **Infrastructure as Code (IaC)**: Deployable templates to programmatically bootstrap the data environment.
- **Architecture Diagram**: Visual blueprint outlining network workflows.
- **Disaster Recovery Plan**: Extensive documentation addressing recovery strategies specifically adapted to data loss, regional outages, or security breaches.

---
