output "data_lake_bucket" {
  description = "S3 bucket used for COPY commands"
  value       = local.data_lake_bucket
}

output "iam_role_arn" {
  description = "RedshiftIAMRole ARN — paste into COPY commands"
  value       = local.iam_role_arn
}

output "sql_file" {
  description = "Run these SQL statements in Redshift Query Editor v2"
  value       = "CDEM3/lab 3/IAC/sql/lab_3_3_queries.sql"
}
