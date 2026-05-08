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
# REFERENCE EXISTING VPC & SUBNETS (from Lab 1.2)
# ─────────────────────────────────────────────

data "aws_vpc" "main" {
  id = "vpc-016a46803312b4334"
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }
  filter {
    name   = "tag:Name"
    values = ["private-subnet-*"]
  }
}

# ─────────────────────────────────────────────
# REFERENCE EXISTING IAM ROLE (from Lab 1.1)
# ─────────────────────────────────────────────

data "aws_iam_role" "redshift" {
  name = "RedshiftIAMRole"
}

# ─────────────────────────────────────────────
# KMS KEY (aws/redshift default)
# ─────────────────────────────────────────────

data "aws_kms_key" "redshift" {
  key_id = "alias/aws/redshift"
}

# ─────────────────────────────────────────────
# SECURITY GROUP
# ─────────────────────────────────────────────

resource "aws_security_group" "redshift" {
  name        = "redshift-security-group"
  description = "Security group for Redshift cluster"
  vpc_id      = data.aws_vpc.main.id

  ingress {
    description = "Redshift port from your IP"
    from_port   = 5439
    to_port     = 5439
    protocol    = "tcp"
    cidr_blocks = ["${var.your_ip}/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "redshift-security-group" }
}

# ─────────────────────────────────────────────
# SUBNET GROUP
# ─────────────────────────────────────────────

resource "aws_redshift_subnet_group" "main" {
  name        = "redshift-tier3-subnet-group"
  description = "Subnet group for Redshift cluster using private subnets"
  subnet_ids  = data.aws_subnets.private.ids

  tags = { Name = "redshift-tier3-subnet-group" }
}

# ─────────────────────────────────────────────
# REDSHIFT CLUSTER
# ─────────────────────────────────────────────

resource "aws_redshift_cluster" "main" {
  cluster_identifier        = "redshift-tier3-lab"
  database_name             = "analytics"
  master_username           = "awsadmin"
  manage_master_password    = true
  node_type                 = "ra3.xlplus"
  number_of_nodes           = 2
  cluster_type              = "multi-node"

  cluster_subnet_group_name = aws_redshift_subnet_group.main.name
  vpc_security_group_ids    = [aws_security_group.redshift.id]

  publicly_accessible       = false
  encrypted                 = true
  kms_key_id                = data.aws_kms_key.redshift.arn

  iam_roles                 = [data.aws_iam_role.redshift.arn]

  automated_snapshot_retention_period = 2

  skip_final_snapshot = true

  tags = {
    Name        = "redshift-tier3-lab"
    Environment = "Learning"
    Purpose     = "Analytics"
    Tier        = "3"
    Lab         = "3.1"
  }
}

# ─────────────────────────────────────────────
# REDSHIFT LOGGING
# ─────────────────────────────────────────────

resource "aws_redshift_logging" "main" {
  cluster_identifier   = aws_redshift_cluster.main.cluster_identifier
  log_destination_type = "cloudwatch"
  log_exports          = ["userlog", "connectionlog", "useractivitylog"]
}
