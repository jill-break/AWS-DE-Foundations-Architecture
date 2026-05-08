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

locals {
  account_id      = "352505432441"
  data_lake_bucket = "data-lake-prod-${local.account_id}"
}

# ─────────────────────────────────────────────
# KINESIS DATA STREAM
# ─────────────────────────────────────────────

resource "aws_kinesis_stream" "user_events" {
  name             = "user-events-stream"
  shard_count      = 4
  retention_period = 24

  stream_mode_details {
    stream_mode = "PROVISIONED"
  }

  tags = {
    Name        = "user-events-stream"
    Environment = "Learning"
    Lab         = "2.3"
  }
}

# ─────────────────────────────────────────────
# IAM ROLE FOR FIREHOSE
# ─────────────────────────────────────────────

resource "aws_iam_role" "firehose" {
  name = "KinesisFirehoseS3Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "firehose.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = {
    Environment = "Learning"
    Lab         = "2.3"
  }
}

resource "aws_iam_role_policy" "firehose" {
  name = "FirehoseKinesisS3Policy"
  role = aws_iam_role.firehose.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "KinesisRead"
        Effect = "Allow"
        Action = [
          "kinesis:GetRecords",
          "kinesis:GetShardIterator",
          "kinesis:DescribeStream",
          "kinesis:ListShards",
          "kinesis:SubscribeToShard"
        ]
        Resource = aws_kinesis_stream.user_events.arn
      },
      {
        Sid    = "S3Write"
        Effect = "Allow"
        Action = [
          "s3:AbortMultipartUpload",
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads",
          "s3:PutObject"
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
# KINESIS FIREHOSE DELIVERY STREAM
# ─────────────────────────────────────────────

resource "aws_kinesis_firehose_delivery_stream" "user_events_to_s3" {
  name        = "user-events-to-s3"
  destination = "extended_s3"

  kinesis_source_configuration {
    kinesis_stream_arn = aws_kinesis_stream.user_events.arn
    role_arn           = aws_iam_role.firehose.arn
  }

  extended_s3_configuration {
    role_arn            = aws_iam_role.firehose.arn
    bucket_arn          = "arn:aws:s3:::${local.data_lake_bucket}"
    prefix              = "streaming-data/"
    error_output_prefix = "streaming-errors/"

    buffering_size     = 5
    buffering_interval = 300
    compression_format = "GZIP"
  }

  tags = {
    Name        = "user-events-to-s3"
    Environment = "Learning"
    Lab         = "2.3"
  }

  depends_on = [aws_iam_role_policy.firehose]
}

# ─────────────────────────────────────────────
# CLOUDWATCH DASHBOARD
# ─────────────────────────────────────────────

resource "aws_cloudwatch_dashboard" "kinesis_monitoring" {
  dashboard_name = "kinesis-monitoring"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "Incoming Records"
          region = var.aws_region
          metrics = [
            ["AWS/Kinesis", "IncomingRecords", "StreamName", "user-events-stream",
              { stat = "Sum", period = 60, label = "Events/min" }]
          ]
          view    = "timeSeries"
          stacked = false
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "Incoming Bytes"
          region = var.aws_region
          metrics = [
            ["AWS/Kinesis", "IncomingBytes", "StreamName", "user-events-stream",
              { stat = "Sum", period = 60, label = "Bytes/min" }]
          ]
          view    = "timeSeries"
          stacked = false
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          title  = "Iterator Age (Latency)"
          region = var.aws_region
          metrics = [
            ["AWS/Kinesis", "GetRecords.IteratorAgeMilliseconds", "StreamName", "user-events-stream",
              { stat = "Maximum", period = 60, label = "Max age ms" }]
          ]
          view    = "timeSeries"
          stacked = false
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          title  = "Read Throughput Exceeded"
          region = var.aws_region
          metrics = [
            ["AWS/Kinesis", "ReadProvisionedThroughputExceeded", "StreamName", "user-events-stream",
              { stat = "Sum", period = 60, label = "Throttled reads" }]
          ]
          view    = "timeSeries"
          stacked = false
        }
      }
    ]
  })
}
