output "source_bucket_name" {
  description = "Name of the DataSync source bucket"
  value       = aws_s3_bucket.source.id
}

output "datasync_task_arn" {
  description = "ARN of the DataSync batch ingestion task"
  value       = aws_datasync_task.batch_ingest.arn
}

output "datasync_source_location_arn" {
  description = "ARN of the DataSync source S3 location"
  value       = aws_datasync_location_s3.source.arn
}

output "datasync_destination_location_arn" {
  description = "ARN of the DataSync destination S3 location"
  value       = aws_datasync_location_s3.destination.arn
}

output "datasync_role_arn" {
  description = "ARN of the IAM role used by DataSync"
  value       = aws_iam_role.datasync.arn
}
