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
  data_lake_bucket = "data-lake-prod-${local.account_id}"
  iam_role_arn     = "arn:aws:iam::${local.account_id}:role/RedshiftIAMRole"
}

# ─────────────────────────────────────────────
# UPLOAD CSV DATA FILES TO S3
# ─────────────────────────────────────────────
# server_side_encryption required by DenyUnencryptedUploads bucket policy

resource "aws_s3_object" "customers_csv" {
  bucket                 = local.data_lake_bucket
  key                    = "raw/customers.csv"
  source                 = "${path.module}/../../data/customers.csv"
  content_type           = "text/csv"
  server_side_encryption = "AES256"
  etag                   = filemd5("${path.module}/../../data/customers.csv")
}

resource "aws_s3_object" "orders_csv" {
  bucket                 = local.data_lake_bucket
  key                    = "raw/orders.csv"
  source                 = "${path.module}/../../data/orders.csv"
  content_type           = "text/csv"
  server_side_encryption = "AES256"
  etag                   = filemd5("${path.module}/../../data/orders.csv")
}

resource "aws_s3_object" "events_csv" {
  bucket                 = local.data_lake_bucket
  key                    = "raw/events.csv"
  source                 = "${path.module}/../../data/events.csv"
  content_type           = "text/csv"
  server_side_encryption = "AES256"
  etag                   = filemd5("${path.module}/../../data/events.csv")
}

# ─────────────────────────────────────────────
# GLUE DATA CATALOG DATABASE (for Spectrum)
# ─────────────────────────────────────────────

resource "aws_glue_catalog_database" "spectrum" {
  name        = "spectrum_db"
  description = "Glue Data Catalog database for Redshift Spectrum external tables"
}
