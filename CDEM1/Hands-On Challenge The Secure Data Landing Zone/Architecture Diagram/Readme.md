This architectural design for the **Secure Data Landing Zone** represents a zero-trust environment specifically hardened for healthcare compliance. By prioritizing **Identity-based Security** over traditional perimeter-based security, this design ensures that sensitive data is isolated, encrypted, and managed without ever traversing the public internet.

## 1. Zero-Trust Network Topology

The foundation is a **Custom VPC** distributed across two **Availability Zones (AZs)**, ensuring that a failure at the data center level does not result in service interruption.

-   **Public Subnets (AZ1 & AZ2):** These subnets act as a structural buffer. While they contain **NAT Gateways**, these are strictly for outbound-only traffic (such as OS security patches). They do not permit any inbound connections from the internet.
    
-   **Private Subnets (The Secure Core):** The **EC2 Processing Node** and **RDS Instances** are hosted here. These subnets have **no route to an Internet Gateway**. All external data interactions are handled via private service endpoints, ensuring the "data landing zone" remains invisible to the public web.

## 2. Identity-Centric Access Control

This architecture eliminates the risk of hardcoded credentials or long-lived SSH keys by leveraging AWS native identity services.

-   **IAM Instance Profile:** The EC2 processing node does not store access keys. Instead, it assumes a temporary, least-privilege **IAM Role** via an Instance Profile. This role is scoped specifically to allow `Read/Write` actions only on the designated S3 bucket and necessary RDS operations.
    
-   **SSM-Based Management:** Administrative access is conducted through **AWS Systems Manager (SSM)**. By using Interface VPC Endpoints, administrators can manage the EC2 node via the AWS private backbone. This removes the need for a Bastion host or an open inbound Port 22, effectively closing the most common vector for brute-force attacks.
## 3. Secure Private Data Routing

A core requirement of this project is the prevention of data traversal over the public internet.

-   **S3 Gateway VPC Endpoint:** This endpoint acts as a private "bridge" within the AWS network. Traffic from the EC2 node or the RDS instance to Amazon S3 is routed through this gateway, bypassing the NAT Gateway and the public internet entirely.
    
-   **Encrypted Data Transit:** All communication between services is forced over **HTTPS (TLS 1.2+)**, ensuring that even within the private network, data is protected from internal sniffing or man-in-the-middle attacks.


## 4. Storage Security & Encryption at Rest

Data protection is enforced at the storage layer to satisfy HIPAA-aligned security standards.

-   **Amazon S3 (Raw Data):** The bucket is configured with **SSE-S3 (AES-256)** encryption by default. A **Restricted Bucket Policy** is applied to explicitly deny any requests that do not originate from the specific VPC Endpoint or the authorized IAM Role.
    
-   **RDS Multi-AZ Resilience:** The database utilizes **Synchronous Replication** between the Primary instance in AZ1 and the Standby instance in AZ2. In the event of a failure, AWS triggers an automatic failover, maintaining the same connection string for the application to ensure near-zero downtime.

## 5. Micro-Segmentation via Security Groups

Security Groups function as stateful, resource-level firewalls to enforce the principle of least privilege at the network layer.

-   **Database Isolation:** The **RDS Security Group** is configured with a single ingress rule: it only allows traffic on the database port (e.g., 5432 for PostgreSQL) if the source is the specific **EC2 Security Group**. This ensures that no other resource—even within the same VPC—can attempt a connection to the database.

## 6. Centralized Disaster Recovery

The architecture integrates **AWS Backup** to provide a unified governance layer for data protection.

-   **Automated Lifecycle Management:** AWS Backup orchestrates daily snapshots of both the RDS instances and the S3 bucket.
    
-   **Vault Lock Protection:** Backups are stored in an encrypted vault. For healthcare compliance, this can be configured with **Vault Lock** to provide WORM (Write Once, Read Many) capability, protecting backups from accidental deletion or ransomware-style encryption attacks.