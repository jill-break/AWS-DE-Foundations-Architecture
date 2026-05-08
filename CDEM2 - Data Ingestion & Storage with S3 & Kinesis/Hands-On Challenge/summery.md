## Project Summary: The Streaming Telemetry Pipeline

I successfully designed and implemented a production-grade **Streaming ETL (Extract, Transform, Load)** pipeline. The architecture was built to handle thousands of delivery trucks by prioritizing cost-efficiency and query performance.

----------

### **The Architecture at a Glance**

1.  **Data Generation (Python/Boto3):**
    
    -   **What we did:** Wrote a script that simulated 100 delivery trucks.
        
    -   **Decision:** Used `boto3` to push data directly via `put_record`. We formatted the data as **JSONLines** (with `\n`) to ensure it remained human-readable and recoverable in case of conversion errors.
        
2.  **Schema Governance (AWS Glue):**
    
    -   **What we did:** Defined a structural "blueprint" for the telemetry data (`vehicle_id`, `timestamp`, `lat/long`, `speed`).
        
    -   **Decision:** Defined the schema **manually** in Glue. This ensured strict data types (e.g., `double` for GPS precision) which is vital for the conversion process.
        
3.  **The Ingestion Engine (Amazon Kinesis Data Firehose):**
    
    -   **What we did:** Provisioned a serverless delivery stream.
        
    -   **Decision:** Enabled **Record Format Conversion**. Firehose acted as the "intelligent bridge," taking raw JSON on one end and outputting optimized **Apache Parquet** on the other.
        
    -   **Optimization:** Configured a **128MB / 300s buffer** to prevent "Small File Syndrome," ensuring high performance for the BI team.
        
4.  **Optimized Storage (Amazon S3):**
    
    -   **What we did:** Set up a Data Lake bucket with automatic partitioning.
        
    -   **Decision:** Implemented **S3 Lifecycle Rules**. Data automatically "ages" from Standard to **Infrequent Access (30 days)** and then to **Glacier (90 days)**, reducing long-term storage costs by up to 95%.
        

----------

### **Key Technical Takeaways**

| Feature        | Strategic Choice                 | Reason                                                                 |
|----------------|----------------------------------|------------------------------------------------------------------------|
| Data Format    | Apache Parquet                  | Columnar storage reduces query costs in Athena and improves speed.     |
| Ingestion      | Firehose                        | Serverless and zero-maintenance compared to Kinesis Data Streams.      |
| Storage        | S3 Lifecycle                    | Aligns storage costs with the data's utility over time.                |
| Monitoring     | CloudWatch & S3 Error Prefix    | Ensures "Dead Letter" logic is in place to catch malformed data.       |

----------

### **The Lifecycle of the Data**

-   **T = 0s:** Truck sends JSON via Python script.
    
-   **T = 1s:** Firehose receives and buffers the record in memory.
    
-   **T = 300s:** Firehose converts the buffer to Parquet using the Glue schema and writes to S3.
    
-   **T = 301s:** Data is immediately queryable via SQL in **Amazon Athena**.
    
-   **T = 30 Days:** Data moves to a cheaper tier (Standard-IA).
    
-   **T = 90 Days:** Data moves to archival storage (Glacier).
    

