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
  account_id       = data.aws_caller_identity.current.account_id
  main_bucket_name = "data-lake-prod-${local.account_id}"
  logs_bucket_name = "data-lake-prod-logs-${local.account_id}"

  common_tags = {
    Environment = "Production"
    Owner       = "DataEngineering"
    Purpose     = "DataLake"
    CostCenter  = "Analytics"
  }
}

# ─────────────────────────────────────────────
# LOGGING BUCKET
# ─────────────────────────────────────────────

resource "aws_s3_bucket" "logs" {
  bucket        = local.logs_bucket_name
  force_destroy = true
  tags          = local.common_tags
}

resource "aws_s3_bucket_public_access_block" "logs" {
  bucket                  = aws_s3_bucket.logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    bucket_key_enabled = true
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# ─────────────────────────────────────────────
# MAIN DATA LAKE BUCKET
# ─────────────────────────────────────────────

resource "aws_s3_bucket" "main" {
  bucket        = local.main_bucket_name
  force_destroy = true
  tags          = local.common_tags
}

resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    bucket_key_enabled = true
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "main" {
  bucket                  = aws_s3_bucket.main.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_logging" "main" {
  bucket        = aws_s3_bucket.main.id
  target_bucket = aws_s3_bucket.logs.id
  target_prefix = "s3-access-logs/"
}

# ─────────────────────────────────────────────
# FOLDER STRUCTURE
# ─────────────────────────────────────────────

resource "aws_s3_object" "folders" {
  for_each               = toset(["raw/", "processed/", "curated/", "temp/", "archive/"])
  bucket                 = aws_s3_bucket.main.id
  key                    = each.value
  content                = ""
  server_side_encryption = "AES256"
}

# ─────────────────────────────────────────────
# LIFECYCLE POLICIES
# ─────────────────────────────────────────────

resource "aws_s3_bucket_lifecycle_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    id     = "archive-processed-data"
    status = "Enabled"

    filter { prefix = "processed/" }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    transition {
      days          = 180
      storage_class = "DEEP_ARCHIVE"
    }
  }

  rule {
    id     = "delete-temp-data-after-1-day"
    status = "Enabled"

    filter { prefix = "temp/" }

    expiration { days = 1 }
  }

  rule {
    id     = "archive-and-delete-after-7-years"
    status = "Enabled"

    filter { prefix = "archive/" }

    transition {
      days          = 1
      storage_class = "GLACIER"
    }

    transition {
      days          = 91
      storage_class = "DEEP_ARCHIVE"
    }

    expiration { days = 2555 }
  }
}

# ─────────────────────────────────────────────
# BUCKET POLICY
# ─────────────────────────────────────────────

resource "aws_s3_bucket_policy" "main" {
  bucket = aws_s3_bucket.main.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyNonHTTPS"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.main.arn,
          "${aws_s3_bucket.main.arn}/*"
        ]
        Condition = {
          Bool = { "aws:SecureTransport" = "false" }
        }
      },
      {
        Sid       = "DenyUnencryptedUploads"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.main.arn}/*"
        Condition = {
          StringNotEquals = {
            "s3:x-amz-server-side-encryption" = "AES256"
          }
        }
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.main]
}
