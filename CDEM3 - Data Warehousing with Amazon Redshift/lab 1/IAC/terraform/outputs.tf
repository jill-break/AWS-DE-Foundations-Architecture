output "cluster_endpoint" {
  description = "Redshift cluster endpoint"
  value       = aws_redshift_cluster.main.endpoint
}

output "cluster_identifier" {
  description = "Redshift cluster identifier"
  value       = aws_redshift_cluster.main.cluster_identifier
}

output "database_name" {
  description = "Redshift database name"
  value       = aws_redshift_cluster.main.database_name
}

output "port" {
  description = "Redshift cluster port"
  value       = aws_redshift_cluster.main.port
}

output "cluster_arn" {
  description = "ARN of the Redshift cluster"
  value       = aws_redshift_cluster.main.arn
}

output "master_password_secret_arn" {
  description = "ARN of the Secrets Manager secret storing the Redshift master password"
  value       = aws_redshift_cluster.main.master_password_secret_arn
}
