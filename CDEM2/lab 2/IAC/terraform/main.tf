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

locals {
  account_id        = data.aws_caller_identity.current.account_id
  source_bucket     = "datasync-source-${local.account_id}"
  data_lake_bucket  = "data-lake-prod-${local.account_id}"
}

# ─────────────────────────────────────────────
# SOURCE BUCKET  (holds the raw CSV files)
# ─────────────────────────────────────────────

resource "aws_s3_bucket" "source" {
  bucket = local.source_bucket

  tags = {
    Name    = "datasync-source"
    Purpose = "DataSync batch ingestion source"
  }
}

resource "aws_s3_bucket_public_access_block" "source" {
  bucket                  = aws_s3_bucket.source.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "source" {
  bucket = aws_s3_bucket.source.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# ─────────────────────────────────────────────
# UPLOAD SAMPLE DATA FILES
# ─────────────────────────────────────────────

resource "aws_s3_object" "customer_master" {
  bucket       = aws_s3_bucket.source.id
  key          = "customer_master.csv"
  source       = "${path.module}/../../data/customer_master.csv"
  content_type = "text/csv"
  etag         = filemd5("${path.module}/../../data/customer_master.csv")
}

resource "aws_s3_object" "sales_history" {
  bucket       = aws_s3_bucket.source.id
  key          = "sales_history.csv"
  source       = "${path.module}/../../data/sales_history.csv"
  content_type = "text/csv"
  etag         = filemd5("${path.module}/../../data/sales_history.csv")
}

resource "aws_s3_object" "transaction_log" {
  bucket       = aws_s3_bucket.source.id
  key          = "transaction_log.csv"
  source       = "${path.module}/../../data/transaction_log.csv"
  content_type = "text/csv"
  etag         = filemd5("${path.module}/../../data/transaction_log.csv")
}

# ─────────────────────────────────────────────
# IAM ROLE FOR DATASYNC
# ─────────────────────────────────────────────

resource "aws_iam_role" "datasync" {
  name        = "DataSyncS3Role"
  description = "Allows DataSync to read the source bucket and write to the data lake"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "datasync.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "datasync" {
  name = "DataSyncS3Access"
  role = aws_iam_role.datasync.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadSource"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = [
          aws_s3_bucket.source.arn,
          "${aws_s3_bucket.source.arn}/*"
        ]
      },
      {
        Sid    = "WriteDestination"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:GetBucketLocation",
          "s3:AbortMultipartUpload",
          "s3:ListMultipartUploadParts"
        ]
        Resource = [
          "arn:aws:s3:::${local.data_lake_bucket}",
          "arn:aws:s3:::${local.data_lake_bucket}/*"
        ]
      }
    ]
  })
}

# ─────────────────────────────────────────────
# DATASYNC LOCATIONS
# ─────────────────────────────────────────────

resource "aws_datasync_location_s3" "source" {
  s3_bucket_arn = aws_s3_bucket.source.arn
  subdirectory  = "/"

  s3_config {
    bucket_access_role_arn = aws_iam_role.datasync.arn
  }

  tags = { Name = "datasync-source-location" }
}

resource "aws_datasync_location_s3" "destination" {
  s3_bucket_arn = "arn:aws:s3:::${local.data_lake_bucket}"
  subdirectory  = "/raw"

  s3_config {
    bucket_access_role_arn = aws_iam_role.datasync.arn
  }

  tags = { Name = "datasync-destination-raw" }
}

# ─────────────────────────────────────────────
# DATASYNC TASK
# ─────────────────────────────────────────────

resource "aws_datasync_task" "batch_ingest" {
  name                     = "batch-ingest-to-data-lake"
  source_location_arn      = aws_datasync_location_s3.source.arn
  destination_location_arn = aws_datasync_location_s3.destination.arn

  options {
    bytes_per_second       = -1
    verify_mode            = "ONLY_FILES_TRANSFERRED"
    overwrite_mode         = "ALWAYS"
    atime                  = "BEST_EFFORT"
    mtime                  = "PRESERVE"
    posix_permissions      = "NONE"
    preserve_deleted_files = "REMOVE"
    uid                    = "NONE"
    gid                    = "NONE"
  }

  schedule {
    schedule_expression = "cron(0 2 * * ? *)"
  }

  tags = {
    Name    = "batch-ingest-to-data-lake"
    Purpose = "Daily batch ingestion of CSV files into raw data lake"
  }
}
