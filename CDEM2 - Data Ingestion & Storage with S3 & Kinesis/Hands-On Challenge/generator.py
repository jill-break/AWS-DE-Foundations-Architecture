import boto3
import json
import time
import random
from datetime import datetime

# Initialize the Firehose client
# Ensure the region matches where you created your stream
firehose = boto3.client('firehose', region_name='us-east-1') 

STREAM_NAME = 'telemetry-ingestion-stream'

def generate_telemetry():
    truck_ids = [f"TRUCK-{i:03d}" for i in range(1, 101)]
    print(f"Starting stream to {STREAM_NAME}... Press Ctrl+C to stop.")
    
    try:
        while True:
            # Create a synthetic data payload
            data = {
                "vehicle_id": random.choice(truck_ids),
                "timestamp": datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S'),
                "latitude": round(random.uniform(5.5, 6.5), 6),  # Focused on Ghana coordinates
                "longitude": round(random.uniform(-0.5, 0.5), 6),
                "speed": round(random.uniform(0, 110), 2)
            }
            
            # Convert dict to JSON string and add a newline
            # The newline is a best practice for downstream parsing
            payload = json.dumps(data) + '\n'
            
            # Put record into the stream
            firehose.put_record(
                DeliveryStreamName=STREAM_NAME,
                Record={'Data': payload}
            )
            
            # Brief sleep to avoid hitting account limits immediately 
            # while still simulating "live" data
            time.sleep(0.2) 
            
    except KeyboardInterrupt:
        print("\nGenerator stopped by user.")

if __name__ == "__main__":
    generate_telemetry()