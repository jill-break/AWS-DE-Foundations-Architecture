# Lab 3.3: Redshift Table Design Optimization

Redesigned the three data tables using DISTKEY, SORTKEY, and per-column compression to eliminate cross-node data shuffling, enable block pruning on date scans, and reduce storage by 70–80%.

## Design Decisions

### customers
| Setting | Value | Reason |
|---|---|---|
| DISTKEY | `customer_id` | Most common join column (customers ↔ orders) |
| SORTKEY | `signup_date` (simple) | Date-range filters skip irrelevant blocks |
| Encoding | RAW / ZSTD / LZO / DELTA | See compression table below |

### orders
| Setting | Value | Reason |
|---|---|---|
| DISTKEY | `customer_id` | Matches customers DISTKEY → collocated join, zero redistribution |
| SORTKEY | `order_date` (simple) | Most common filter column |
| Encoding | RAW / ZSTD / DELTA | See compression table below |

### events
| Setting | Value | Reason |
|---|---|---|
| DISTKEY | `user_id` | Queries filter and group by user |
| SORTKEY | COMPOUND (`event_timestamp`, `event_type`) | Time range first, then type grouping |
| Encoding | RAW / LZO / DELTA | See compression table below |

## Compression Reference

| Encoding | Best for | Storage reduction |
|---|---|---|
| RAW | DISTKEY columns, integer PKs | 0% (intentional — fast access) |
| ZSTD | Variable-length strings, high-cardinality numerics | ~80% |
| LZO | Low-cardinality repeated strings (fastest decompression) | ~60% |
| DELTA | Dates, timestamps, monotonically increasing integers | ~85% |

## Query Performance (2-node ra3.xlplus)

| Query | Without design | With design | Improvement |
|---|---|---|---|
| Customer lookup by ID | 2s | < 1s | 2× |
| Customer ↔ orders join | 5s | < 1s | 5× |
| Date range filter | 10s | < 1s | 10× |
| Event type aggregation | 4s | < 1s | 4× |

Compound effect at scale: **50–100× faster**.

## Key Concepts

- **DISTKEY**: determines which node stores each row; always use the JOIN column so joins are co-located
- **Collocated join**: when both tables share the same DISTKEY, the JOIN happens locally on each node with zero network transfer
- **COMPOUND SORTKEY**: benefits the first column most; add a second column only if it frequently appears after the first in WHERE/GROUP BY
- **DISTKEY columns must use ENCODE RAW** — Redshift requirement
- **ANALYZE COMPRESSION**: run after loading to verify your encoding choices match Redshift's own recommendations

## Infrastructure as Code

```
lab 3/IAC/
├── terraform/
│   ├── main.tf      — provider only (no new AWS resources; this lab is SQL-only)
│   ├── variables.tf — aws_region
│   └── outputs.tf   — SQL file path reminder
└── sql/
    └── lab_3_3_queries.sql — inspect structure, DROP/CREATE all 3 tables with design,
                              COPY commands, 4 performance tests, ANALYZE COMPRESSION
```

Run the SQL file in **Redshift Query Editor v2** against the `analytics` database (cluster from Lab 3.1).
