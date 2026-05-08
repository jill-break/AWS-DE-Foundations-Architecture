output "main_bucket_name" {
  description = "Name of the main data lake bucket"
  value       = aws_s3_bucket.main.id
}

output "main_bucket_arn" {
  description = "ARN of the main data lake bucket"
  value       = aws_s3_bucket.main.arn
}

output "logs_bucket_name" {
  description = "Name of the access logs bucket"
  value       = aws_s3_bucket.logs.id
}

output "logs_bucket_arn" {
  description = "ARN of the access logs bucket"
  value       = aws_s3_bucket.logs.arn
}
