# AWS Data Engineering Foundations - Course Repository

This repository serves as the central hub for the AWS Data Engineering Foundations program (Phase 2), demonstrating the practical application of secure, scalable, and resilient cloud architecture. The structure is separated into sequential modules designed to build a foundational understanding of AWS infrastructure.

## Repository Architecture and Organization

The repository is divided into discrete learning modules (CDEM folders). Below is a comprehensive overview of the contents and objectives for each module.

### CDEM1: Secure Architecture and Core Networking

This directory contains the primary documentation and hands-on exercises for building a well-architected data engineering platform. Its main focus is on securing cloud infrastructure by rigidly applying the Principle of Least Privilege and establishing isolated, multi-tier network topologies.

Key areas covered in this module include:

- **Identity and Access Management (Lab 1)**: Focuses on creating custom roles and defining explicit permissions boundaries. This includes the configuration of specific roles like the `DataEngineerRole`, `GlueServiceRole`, and `LambdaExecutionRole`. It also covers the development of custom security policies tailored for secure data lake access and mandatory server-side encryption.
- **Virtual Private Cloud and Subnet Layering (Lab 2)**: Explores network isolation by architecting a custom VPC (`data-platform-vpc`) securely segmented into public and private layers across multiple Availability Zones. This section deals with NAT Gateways for outbound internet access, internal traffic routing via VPC endpoints (S3 and DynamoDB), and ensuring database and compute instances remain completely severed from inbound external traffic.
- **The Secure Data Landing Zone (Hands-On Challenge)**: A comprehensive capstone project that ties together the principles of IAM and VPCs using Infrastructure as Code (IaC) templates. It features comprehensive architecture diagrams and details practical disaster recovery plans designed to mitigate data loss or regional outages.

### CDEM2: Upcoming Modules

This directory is currently reserved for future course iterations and intermediate-level database management modules. Future topics to be placed here may involve advanced data pipeline orchestrations or further analytics integrations.

---

*Note: All architecture and configurations within this repository prioritize robust security and adhere to AWS best practices for cloud data infrastructure.*
