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
# Lab 3.3 is SQL-only. No new AWS infrastructure
# is created here. The Redshift cluster and S3 data
# were provisioned in Labs 3.1 and 3.2.
#
# All optimized table DDL (DISTKEY, SORTKEY,
# compression) is in: IAC/sql/lab_3_3_queries.sql
# ─────────────────────────────────────────────
