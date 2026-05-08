terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

# ─────────────────────────────────────────────
# CUSTOM POLICIES
# ─────────────────────────────────────────────

resource "aws_iam_policy" "data_lake_bucket_access" {
  name        = "DataLakeBucketAccessPolicy"
  description = "Restrict S3 access to data-lake buckets only and blocks unencrypted uploads"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ListDataLakeBucket"
        Effect = "Allow"
        Action = ["s3:ListBucket", "s3:GetBucketLocation"]
        Resource = "arn:aws:s3:::data-lake-*"
      },
      {
        Sid    = "ReadWriteDataLakeObjects"
        Effect = "Allow"
        Action = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Resource = "arn:aws:s3:::data-lake-*/*"
      },
      {
        Sid    = "DenyUnencryptedUploads"
        Effect = "Deny"
        Action = "s3:PutObject"
        Resource = "arn:aws:s3:::data-lake-*/*"
        Condition = {
          StringNotEquals = {
            "s3:x-amz-server-side-encryption" = "AES256"
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "quicksight_read_only" {
  name        = "QuickSightReadOnlyAccess"
  description = "Allow read-only access to QuickSight for analysts"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "QuickSightReadOnlyAccess"
        Effect = "Allow"
        Action = ["quicksight:Describe*", "quicksight:List*", "quicksight:Get*"]
        Resource = "*"
      }
    ]
  })
}

# ─────────────────────────────────────────────
# ROLES
# ─────────────────────────────────────────────

resource "aws_iam_role" "data_engineer" {
  name        = "DataEngineerRole"
  description = "Main role for data engineers"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" }
      Action    = "sts:AssumeRole"
    }]
  })
}

locals {
  data_engineer_policies = {
    "AmazonS3FullAccess"               = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
    "AWSGlueConsoleFullAccess"         = "arn:aws:iam::aws:policy/AWSGlueConsoleFullAccess"
    "AmazonRedshiftFullAccess"         = "arn:aws:iam::aws:policy/AmazonRedshiftFullAccess"
    "AmazonElasticMapReduceFullAccess" = "arn:aws:iam::aws:policy/AmazonElasticMapReduceFullAccess"
    "AmazonKinesisFullAccess"          = "arn:aws:iam::aws:policy/AmazonKinesisFullAccess"
    "AWSLambda_FullAccess"             = "arn:aws:iam::aws:policy/AWSLambda_FullAccess"
    "CloudWatchFullAccess"             = "arn:aws:iam::aws:policy/CloudWatchFullAccess"
    "DataLakeBucketAccessPolicy"       = aws_iam_policy.data_lake_bucket_access.arn
  }
}

resource "aws_iam_role_policy_attachment" "data_engineer" {
  for_each   = local.data_engineer_policies
  role       = aws_iam_role.data_engineer.name
  policy_arn = each.value
}

resource "aws_iam_role" "glue_service" {
  name        = "GlueServiceRole"
  description = "For Glue jobs to use"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "glue.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

locals {
  glue_policies = [
    "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole",
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",
    "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess",
    "arn:aws:iam::aws:policy/SecretsManagerReadWrite",
  ]
}

resource "aws_iam_role_policy_attachment" "glue_service" {
  for_each   = toset(local.glue_policies)
  role       = aws_iam_role.glue_service.name
  policy_arn = each.value
}

resource "aws_iam_role" "lambda_execution" {
  name        = "LambdaExecutionRole"
  description = "For Lambda functions to use"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

locals {
  lambda_policies = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",
    "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess",
    "arn:aws:iam::aws:policy/AmazonKinesisFullAccess",
    "arn:aws:iam::aws:policy/SecretsManagerReadWrite",
  ]
}

resource "aws_iam_role_policy_attachment" "lambda_execution" {
  for_each   = toset(local.lambda_policies)
  role       = aws_iam_role.lambda_execution.name
  policy_arn = each.value
}

resource "aws_iam_role" "redshift" {
  name        = "RedshiftIAMRole"
  description = "For Redshift to access S3"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "redshift.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

locals {
  redshift_policies = [
    "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess",
    "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess",
  ]
}

resource "aws_iam_role_policy_attachment" "redshift" {
  for_each   = toset(local.redshift_policies)
  role       = aws_iam_role.redshift.name
  policy_arn = each.value
}

resource "aws_iam_role" "analyst_read_only" {
  name        = "AnalystReadOnlyRole"
  description = "For analysts to query data safely"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" }
      Action    = "sts:AssumeRole"
    }]
  })
}

locals {
  analyst_policies = {
    "AmazonRedshiftReadOnlyAccess" = "arn:aws:iam::aws:policy/AmazonRedshiftReadOnlyAccess"
    "AmazonAthenaFullAccess"       = "arn:aws:iam::aws:policy/AmazonAthenaFullAccess"
    "AmazonS3ReadOnlyAccess"       = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
    "QuickSightReadOnlyAccess"     = aws_iam_policy.quicksight_read_only.arn
  }
}

resource "aws_iam_role_policy_attachment" "analyst_read_only" {
  for_each   = local.analyst_policies
  role       = aws_iam_role.analyst_read_only.name
  policy_arn = each.value
}
