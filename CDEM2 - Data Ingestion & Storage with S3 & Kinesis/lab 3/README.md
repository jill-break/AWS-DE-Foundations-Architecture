# Lab 2.3: Kinesis Real-Time Streaming

Built a real-time event streaming pipeline: a Python producer sends user video-streaming events to a Kinesis Data Stream, a Python consumer reads all shards in parallel, and Kinesis Firehose automatically backs everything up to S3 as compressed JSON.

## Architecture

```
Python Producer ──► Kinesis Data Stream ──► Python Consumer
  (5 events/s)       (user-events-stream)    (4 threads, 1/shard)
                           │
                    Kinesis Firehose
                  (user-events-to-s3)
                           │
                    S3: streaming-data/
                  (GZIP, 5MB or 300s buffer)
```

## What We Built

| Resource | Name / Config | Notes |
|---|---|---|
| Kinesis Data Stream | `user-events-stream` | 4 shards, 24h retention, provisioned mode |
| IAM role | `KinesisFirehoseS3Role` | Trusted by `firehose.amazonaws.com` |
| Kinesis Firehose | `user-events-to-s3` | Source: Kinesis stream; dest: S3 `streaming-data/` |
| Firehose buffer | 5 MB / 300 seconds | Whichever threshold is reached first triggers a flush |
| Compression | GZIP | Applied by Firehose before writing to S3 |
| CloudWatch dashboard | `kinesis-monitoring` | 4 widgets: IncomingRecords, IncomingBytes, IteratorAge, Throttling |

## Performance

| Metric | Value |
|---|---|
| End-to-end latency | < 1 second |
| Test throughput | ~5 events/second |
| Max throughput | 4,000 events/second (4 shards × 1,000/s) |
| Data loss | 0 (Firehose guarantees at-least-once delivery) |

## Event Types

`play`, `pause`, `resume`, `seek`, `buffer`, `quality_change`, `error`, `complete`

## Key Concepts

- **Partition key = `user_id`**: events for the same user always land on the same shard, preserving per-user ordering
- **Parallel shard consumption**: consumer spawns one thread per shard — all 4 shards are read concurrently
- **Firehose as durable backup**: stream data is ephemeral (24h); Firehose writes permanent copies to S3
- **IteratorAge**: the key latency metric — how far behind the consumer is from the head of the stream

## Infrastructure as Code

```
lab 3/IAC/terraform/
├── main.tf      — Kinesis stream, Firehose IAM role + policy,
│                  Firehose delivery stream, CloudWatch dashboard
├── variables.tf — aws_region
└── outputs.tf   — stream ARN, Firehose ARN, S3 prefix, dashboard URL
```

```
lab 3/scripts/
├── kinesis_producer.py — sends ~150 events over 30s; partition key = user_id
└── kinesis_consumer.py — parallel shard readers; emits custom CloudWatch metrics
```

## Quick Start

```bash
cd "lab 3/IAC/terraform"
terraform init
terraform apply

pip install boto3

# Terminal 1 — produce events
python "lab 3/scripts/kinesis_producer.py"

# Terminal 2 — consume events
python "lab 3/scripts/kinesis_consumer.py"
```

> **Teardown**: `terraform destroy` — deletes stream, Firehose, IAM role, dashboard
