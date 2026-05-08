output "kinesis_stream_arn" {
  description = "ARN of the Kinesis Data Stream"
  value       = aws_kinesis_stream.user_events.arn
}

output "kinesis_stream_name" {
  description = "Name of the Kinesis Data Stream"
  value       = aws_kinesis_stream.user_events.name
}

output "firehose_arn" {
  description = "ARN of the Firehose delivery stream"
  value       = aws_kinesis_firehose_delivery_stream.user_events_to_s3.arn
}

output "s3_streaming_prefix" {
  description = "S3 prefix where Firehose writes streaming data"
  value       = "s3://data-lake-prod-352505432441/streaming-data/"
}

output "cloudwatch_dashboard_url" {
  description = "CloudWatch dashboard for monitoring the stream"
  value       = "https://console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=kinesis-monitoring"
}

output "producer_script" {
  description = "Run this script to produce events to the stream"
  value       = "CDEM2/lab 3/scripts/kinesis_producer.py"
}

output "consumer_script" {
  description = "Run this script to consume events from the stream"
  value       = "CDEM2/lab 3/scripts/kinesis_consumer.py"
}
