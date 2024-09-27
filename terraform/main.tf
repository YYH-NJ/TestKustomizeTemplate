provider "aws" {
  region = "{{ $sys.deploymentCell.region }}"
}

# Globals
resource "random_string" "suffix" {
  length  = 5
  upper   = false
  lower   = true
  special = false
}


locals {
  region = "{{ $sys.deploymentCell.region }}"
  availability_zones = [
    "${local.region}a",
    "${local.region}b",
    "${local.region}d"
  ]
  vpc_id = "{{ $sys.deploymentCell.cloudProviderNetworkID }}"
  subnet_ids = [
    "{{ $sys.deploymentCell.publicSubnetIDs[0].id }}",
    "{{ $sys.deploymentCell.publicSubnetIDs[1].id }}",
    "{{ $sys.deploymentCell.publicSubnetIDs[2].id }}"
  ]

  s3_bucket_name = "some-bucket-name-new-${random_string.suffix.result}"
}

# S3 Bucket
data "aws_kms_alias" "s3" {
  name = "alias/aws/s3"
}

module "db_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.1.1"

  bucket = local.s3_bucket_name

  # S3 bucket-level Public Access Block configuration
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        kms_master_key_id = data.aws_kms_alias.s3.id
        sse_algorithm     = "aws:kms"
      }
      bucket_key_enabled = true
    }
  }

  lifecycle_rule = [
    {
      id      = "expire-cache-objs"
      enabled = true

      filter = {
        prefix = "_cache/"
      }

      expiration = {
        days = 60
      }
    }
  ]
}


output "bucket_url" {
  value = {
    arn: module.db_bucket.s3_bucket_arn
  }
  sensitive = true
}