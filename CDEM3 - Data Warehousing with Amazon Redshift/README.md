# CDEM3: Redshift Analytics

Provisioned an Amazon Redshift cluster in the secure data-platform VPC, loaded data from the S3 data lake using the COPY command, queried cold data directly from S3 via Redshift Spectrum, and applied table design optimizations (DISTKEY, SORTKEY, compression) for 5–10× query performance improvements.

---

## Labs

### [Lab 3.1 — Redshift Cluster Setup](lab%201/README.md)

Provisioned the analytics cluster with production security settings.

- Cluster `redshift-tier3-lab`: 2 × `ra3.xlplus` nodes, database `analytics`
- KMS encryption, Secrets Manager password (`manage_master_password = true`)
- VPC: `vpc-016a46803312b4334`, private subnets, IP-restricted security group (port 5439)
- CloudWatch audit logging via `aws_redshift_logging` resource (inline block deprecated in provider v5)
- IAM role `RedshiftIAMRole` attached for COPY access to S3
- Cost: ~$0.96/hour — destroy when not in use
- IaC: Terraform → `lab 1/IAC/terraform/`

### [Lab 3.2 — COPY Command + Redshift Spectrum](lab%202/README.md)

Loaded data into Redshift via COPY and queried the same data externally via Spectrum.

- 3 tables loaded via COPY: `customers` (10 rows), `orders` (15 rows), `events` (100 rows)
- Spectrum external table `events_external` — queries S3 directly, zero load time
- Glue Data Catalog database `spectrum_db` as metadata store for Spectrum
- COPY is fast (parallel, < 1s for small datasets); Spectrum costs $6.25/TB scanned
- Decision: COPY for hot data, Spectrum for cold/archive data
- IaC: Terraform uploads CSVs to S3, creates Glue DB → `lab 2/IAC/terraform/`
- SQL: `lab 2/IAC/sql/lab_3_2_queries.sql`

### [Lab 3.3 — Table Design Optimization](lab%203/README.md)

Redesigned all three tables with DISTKEY, SORTKEY, and compression for maximum query speed.

- `customers`: `DISTKEY(customer_id)`, `SORTKEY(signup_date)` — fast lookups + date range pruning
- `orders`: `DISTKEY(customer_id)` — collocated join with customers, zero data redistribution
- `events`: `DISTKEY(user_id)`, `COMPOUND SORTKEY(event_timestamp, event_type)` — time-range + aggregation
- Compression: RAW (DISTKEY cols), DELTA (dates/timestamps), ZSTD (strings), LZO (repeated strings)
- Storage reduction: 70–80% vs uncompressed; query improvement: 5–10× (up to 100× at scale)
- IaC: SQL-only lab → `lab 3/IAC/sql/lab_3_3_queries.sql`

---

## Key AWS Services

| Service | Used for |
|---|---|
| Amazon Redshift | Columnar MPP analytics database |
| Amazon S3 | Source data for COPY; cold storage for Spectrum |
| AWS Glue Data Catalog | External schema metadata for Redshift Spectrum |
| AWS Secrets Manager | Redshift master password storage and rotation |
| AWS KMS | Cluster-level encryption at rest |
| Amazon CloudWatch | Audit logs (user activity, connections) |
| Terraform | IaC for cluster and data upload |

---

## Key Design Rules (for future labs)

| Rule | Why |
|---|---|
| DISTKEY = JOIN column | Ensures co-located joins with zero network transfer |
| SORTKEY = WHERE/ORDER BY column | Enables block pruning — Redshift skips irrelevant blocks |
| Matching DISTKEYs across joined tables | Required for collocated joins |
| DISTKEY columns → ENCODE RAW | Redshift requirement |
| Dates/timestamps → ENCODE DELTA | Stores differences, not full values — ~85% reduction |
| Run ANALYZE COMPRESSION after load | Verifies your encoding choices vs Redshift's recommendations |
