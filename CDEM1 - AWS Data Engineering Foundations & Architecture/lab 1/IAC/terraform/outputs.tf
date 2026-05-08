output "data_engineer_role_arn" {
  description = "ARN of the DataEngineerRole"
  value       = aws_iam_role.data_engineer.arn
}

output "glue_service_role_arn" {
  description = "ARN of the GlueServiceRole"
  value       = aws_iam_role.glue_service.arn
}

output "lambda_execution_role_arn" {
  description = "ARN of the LambdaExecutionRole"
  value       = aws_iam_role.lambda_execution.arn
}

output "redshift_role_arn" {
  description = "ARN of the RedshiftIAMRole"
  value       = aws_iam_role.redshift.arn
}

output "analyst_read_only_role_arn" {
  description = "ARN of the AnalystReadOnlyRole"
  value       = aws_iam_role.analyst_read_only.arn
}
