# Lab 3.2: Redshift COPY Command + Spectrum

Loaded CSV data from S3 into Redshift using the COPY command, then queried the same data directly from S3 via Redshift Spectrum — demonstrating the trade-offs between hot (loaded) and cold (external) data access patterns.

## What We Built

| Resource | Type | Location | Rows |
|---|---|---|---|
| `customers` | Redshift table (COPY) | Cluster storage | 10 |
| `orders` | Redshift table (COPY) | Cluster storage | 15 |
| `events` | Redshift table (COPY) | Cluster storage | 100 |
| `events_external` | Spectrum external table | S3 (no load) | 100 |
| `spectrum_db` | Glue Data Catalog DB | Metadata store | — |
| CSV files | S3 objects | `data-lake-prod-352505432441/raw/` | — |

## Performance Comparison

| Pattern | Query time | Load time | Cost/month | Best for |
|---|---|---|---|---|
| COPY table | < 1s | < 5s | Included | Daily analysis, joins, dashboards |
| Spectrum table | 1–3s | 0s | $6.25/TB scanned | Rare historical queries |
| S3 storage | — | — | ~$0.023/GB | Cold archive |

**Decision**: use COPY for hot data queried daily; use Spectrum for cold data queried rarely.

## Key Concepts

- **COPY is parallel**: Redshift splits the S3 file across all nodes — much faster than `INSERT` row-by-row
- **Spectrum queries S3 directly**: no data moves into the cluster — you pay per TB scanned ($6.25)
- **Glue Data Catalog**: Spectrum reads table metadata (schema, location) from Glue, not Redshift's internal catalog
- **`IGNOREHEADER 1`**: required for CSV files with a header row; omitting it silently loads the header as a data row
- **Reserved keyword**: column named `event_timestamp` not `timestamp` — `TIMESTAMP` is a SQL reserved word

## Infrastructure as Code

```
lab 2/
├── data/
│   ├── customers.csv   — 10 rows of sample customer data
│   ├── orders.csv      — 15 rows of sample order data
│   └── events.csv      — 100 rows of sample event data
└── IAC/
    ├── terraform/
    │   ├── main.tf      — S3 object uploads (with AES256), Glue catalog database
    │   ├── variables.tf — aws_region
    │   └── outputs.tf   — S3 paths, IAM role ARN, Glue DB name
    └── sql/
        └── lab_3_2_queries.sql — DDL, COPY commands, Spectrum setup, perf comparison
```

## Quick Start

```bash
cd "lab 2/IAC/terraform"
terraform init
terraform apply   # uploads CSVs to S3, creates Glue DB
```

Then open Redshift Query Editor v2 and run `lab_3_2_queries.sql` section by section.
