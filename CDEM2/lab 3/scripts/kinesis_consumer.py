"""
Kinesis Consumer — Lab 2.3
Reads events from all shards of user-events-stream in parallel,
prints them to the terminal, and emits custom CloudWatch metrics.

Usage:
    pip install boto3
    python kinesis_consumer.py
"""

import boto3
import json
import threading
import time
from datetime import datetime

STREAM_NAME = "user-events-stream"
REGION = "us-east-1"
POLL_INTERVAL = 1  # seconds between GetRecords calls per shard
ITERATOR_TYPE = "LATEST"  # LATEST = only new records; TRIM_HORIZON = all records

kinesis_client = boto3.client("kinesis", region_name=REGION)
cloudwatch_client = boto3.client("cloudwatch", region_name=REGION)

total_processed = 0
lock = threading.Lock()


def emit_cloudwatch_metric(event_type: str):
    cloudwatch_client.put_metric_data(
        Namespace="KinesisLab/UserEvents",
        MetricData=[
            {
                "MetricName": "EventsProcessed",
                "Dimensions": [{"Name": "EventType", "Value": event_type}],
                "Value": 1,
                "Unit": "Count",
                "Timestamp": datetime.utcnow(),
            }
        ],
    )


def process_record(record: dict, shard_id: str):
    global total_processed
    data = json.loads(record["Data"])
    arrival = record["ApproximateArrivalTimestamp"]
    latency_ms = int((datetime.utcnow().timestamp() - arrival.timestamp()) * 1000)

    with lock:
        total_processed += 1
        count = total_processed

    print(
        f"[{count:>4}] shard={shard_id[-4:]}  "
        f"type={data.get('event_type', '?'):<15} "
        f"user={data.get('user_id', '?')}  "
        f"latency={latency_ms}ms"
    )

    try:
        emit_cloudwatch_metric(data.get("event_type", "unknown"))
    except Exception:
        pass


def consume_shard(shard_id: str):
    response = kinesis_client.get_shard_iterator(
        StreamName=STREAM_NAME,
        ShardId=shard_id,
        ShardIteratorType=ITERATOR_TYPE,
    )
    iterator = response["ShardIterator"]

    print(f"  Shard {shard_id} — iterator obtained, polling every {POLL_INTERVAL}s")

    while True:
        try:
            response = kinesis_client.get_records(ShardIterator=iterator, Limit=100)
            records = response.get("Records", [])

            for record in records:
                process_record(record, shard_id)

            iterator = response.get("NextShardIterator")
            if not iterator:
                print(f"  Shard {shard_id} — iterator expired, stopping")
                break

        except kinesis_client.exceptions.ExpiredIteratorException:
            print(f"  Shard {shard_id} — iterator expired, re-fetching")
            response = kinesis_client.get_shard_iterator(
                StreamName=STREAM_NAME,
                ShardId=shard_id,
                ShardIteratorType="LATEST",
            )
            iterator = response["ShardIterator"]

        except Exception as exc:
            print(f"  Shard {shard_id} — error: {exc}")
            time.sleep(5)
            continue

        time.sleep(POLL_INTERVAL)


def main():
    stream = kinesis_client.describe_stream(StreamName=STREAM_NAME)
    shards = stream["StreamDescription"]["Shards"]

    print(f"Stream '{STREAM_NAME}' — {len(shards)} shards found")
    print("Starting parallel consumers (Ctrl+C to stop)...\n")

    threads = []
    for shard in shards:
        t = threading.Thread(
            target=consume_shard,
            args=(shard["ShardId"],),
            daemon=True,
        )
        t.start()
        threads.append(t)

    try:
        while True:
            time.sleep(10)
            with lock:
                print(f"\n--- Total processed so far: {total_processed} events ---\n")
    except KeyboardInterrupt:
        with lock:
            print(f"\nStopped. Total events processed: {total_processed}")


if __name__ == "__main__":
    main()
