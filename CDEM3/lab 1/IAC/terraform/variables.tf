variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "your_ip" {
  description = "Your public IP address (without /32) to allow Redshift access on port 5439"
  type        = string
}
