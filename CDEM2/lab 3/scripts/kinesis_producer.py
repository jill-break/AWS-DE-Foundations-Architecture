"""
Kinesis Producer — Lab 2.3
Generates simulated user video-streaming events and puts them onto
the user-events-stream Kinesis Data Stream at ~5 events/second.

Usage:
    pip install boto3
    python kinesis_producer.py
"""

import boto3
import json
import random
import time
import uuid
from datetime import datetime

STREAM_NAME = "user-events-stream"
REGION = "us-east-1"
EVENTS_PER_SECOND = 5
DURATION_SECONDS = 30

EVENT_TYPES = ["play", "pause", "resume", "seek", "buffer", "quality_change", "error", "complete"]
CONTENT_IDS = [f"video_{i:03d}" for i in range(1, 21)]
USER_IDS = [f"user_{i:04d}" for i in range(1, 101)]
DEVICES = ["web", "mobile", "tablet", "smart_tv", "desktop"]
QUALITIES = ["480p", "720p", "1080p", "4K"]


def generate_event():
    event_type = random.choice(EVENT_TYPES)
    user_id = random.choice(USER_IDS)
    content_id = random.choice(CONTENT_IDS)

    event = {
        "event_id": str(uuid.uuid4()),
        "user_id": user_id,
        "session_id": f"sess_{random.randint(10000, 99999)}",
        "content_id": content_id,
        "event_type": event_type,
        "timestamp": datetime.utcnow().isoformat() + "Z",
        "device_type": random.choice(DEVICES),
        "quality": random.choice(QUALITIES),
    }

    if event_type in ("play", "resume", "seek"):
        event["position_seconds"] = random.randint(0, 3600)
    if event_type == "seek":
        event["seek_to_seconds"] = random.randint(0, 3600)
    if event_type == "buffer":
        event["buffer_duration_ms"] = random.randint(100, 5000)
    if event_type == "quality_change":
        event["previous_quality"] = random.choice(QUALITIES)
    if event_type == "error":
        event["error_code"] = random.choice(["NET_ERR", "DRM_ERR", "CODEC_ERR", "TIMEOUT"])

    return event, user_id


def main():
    kinesis = boto3.client("kinesis", region_name=REGION)

    print(f"Producing events to '{STREAM_NAME}' for {DURATION_SECONDS} seconds...")
    print(f"Rate: {EVENTS_PER_SECOND} events/second\n")

    total_sent = 0
    start = time.time()
    interval = 1.0 / EVENTS_PER_SECOND

    while time.time() - start < DURATION_SECONDS:
        event, user_id = generate_event()
        payload = json.dumps(event)

        kinesis.put_record(
            StreamName=STREAM_NAME,
            Data=payload.encode("utf-8"),
            PartitionKey=user_id,
        )

        total_sent += 1
        print(f"[{total_sent:>4}] {event['event_type']:<15} user={user_id}  content={event['content_id']}")
        time.sleep(interval)

    elapsed = time.time() - start
    print(f"\nDone. Sent {total_sent} events in {elapsed:.1f}s ({total_sent / elapsed:.1f} events/sec)")


if __name__ == "__main__":
    main()
