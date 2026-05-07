output "customers_s3_path" {
  description = "S3 path for customers.csv"
  value       = "s3://${local.data_lake_bucket}/raw/customers.csv"
}

output "orders_s3_path" {
  description = "S3 path for orders.csv"
  value       = "s3://${local.data_lake_bucket}/raw/orders.csv"
}

output "events_s3_path" {
  description = "S3 path for events.csv"
  value       = "s3://${local.data_lake_bucket}/raw/events.csv"
}

output "iam_role_arn" {
  description = "RedshiftIAMRole ARN — paste into COPY commands"
  value       = local.iam_role_arn
}

output "glue_database_name" {
  description = "Glue catalog database name for the Spectrum external schema"
  value       = aws_glue_catalog_database.spectrum.name
}

output "sql_file" {
  description = "Ready-to-run SQL for Redshift Query Editor v2"
  value       = "CDEM3/lab 2/IAC/sql/lab_3_2_queries.sql"
}
