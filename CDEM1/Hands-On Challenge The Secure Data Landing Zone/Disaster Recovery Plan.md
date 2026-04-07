# Secure Data Landing Zone: Disaster Recovery & Incident Response Plan

## 1. Overview
This formal Disaster Recovery (DR) and Incident Response plan governs the expectations, configurations, and restoration procedures for the Secure Data Landing Zone environment. The objective is to ensure minimal data loss and rapid recovery in the event of component failure, accidental deletion, or malicious activity (e.g., ransomware).

## 2. Recovery Objectives
To meet the stringent resilience requirements of healthcare analytics operations, the following Service Level Objectives (SLOs) are defined:

### Recovery Point Objective (RPO)
**RPO is the maximum acceptable amount of data loss measured in time.**
- **RDS (PostgreSQL):** **5 Minutes**. The RDS instance utilizes automated backups combined with transaction log backups, allowing for Point-in-Time Recovery (PITR) up to the second, with a maximum data at risk window of approximately 5 minutes for transaction logs not yet continuously backed up.
- **S3 Raw Data Bucket:** **24 Hours**. The bucket is backed up daily. (Note: For stricter requirements, Amazon S3 Versioning can be enabled to provide immediate rollback capabilities against accidental overwrites/deletions).

### Recovery Time Objective (RTO)
**RTO is the maximum acceptable time to restore service after a disruption.**
- **RDS Multi-AZ Failover:** **< 2 Minutes**. In the event of primary database availability zone failure, AWS automatically promotes the synchronous standby instance to primary. The application connection string remains the same.
- **Full Database Restoration (from Backup):** **< 30 Minutes**, dependent on database size.
- **S3 Data Restoration:** Variable based on dataset size, initiating restoration via AWS Backup.

## 3. AWS Backup Utilization
The architecture leverages **AWS Backup** as the centralized data protection and governance layer.

- **Automated Discovery:** Resources (RDS, S3) are dynamically assigned to the backup plan using the tag `Backup-Policy: Healthcare-Daily`.
- **Backup Plan:** `HealthcareDailyBackup` executes a daily snapshot of all tagged resources.
- **Vault Location:** Backups are stored in `HealthcareVault`.
- **Retention:** Backups are retained for **30 Days**.
- **Immutability (Recommended):** The vault can be configured with **AWS Backup Vault Lock** in compliance mode to prevent deletion or alteration of backups even by administrators with full privileges.

## 4. Incident Response Steps
In the event of an incident requiring data restoration, the following procedures must be followed:

### Scenario A: Accidental Data Deletion / Ransomware (S3)
1. **Identify Incident Time:** Determine the exact time the malicious activity or accidental deletion occurred.
2. **Access AWS Backup Console:** Navigate to AWS Backup -> Protected Resources.
3. **Select Latest Uncompromised Recovery Point:** Select the S3 recovery point from immediately prior to the incident.
4. **Initiate Restore:** Choose to restore the data.
   - *Option 1 (In-Place):* Restore into the existing bucket (overwriting current state).
   - *Option 2 (Investigation):* Restore to a securely isolated new S3 bucket for forensics before merging valid data back.

### Scenario B: Database Corruption or Data Loss (RDS)
1. **Determine Recovery Point:** Identify the exact timestamp of the corruption.
2. **Access RDS Console:** Navigate to RDS -> Databases -> Selecting the affected instance.
3. **Initiate Point-in-Time Recovery (PITR):** Select "Restore to point in time". Input a time immediately preceding the corruption.
4. **Provision New Instance:** AWS will provision a new RDS instance with the restored data.
5. **Downtime Management:** Update application configurations or secrets manager to point to the new RDS instance endpoint once it becomes available. Delete the corrupted instance after verification.

### Scenario C: Complete AZ Failure
1. **No Action Required for Database:** Multi-AZ RDS automatically fails over to the secondary Availability Zone.
2. **Compute Node Adjustment:** If the `t3.micro` instance in the primary private subnet fails, provision a new instance in the secondary private subnet using the `landing-zone.yaml` template or Auto Scaling Group (if implemented in future iterations). S3 Endpoints and SSM are configured across both AZs to ensure continuous access.
