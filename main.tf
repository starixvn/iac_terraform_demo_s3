resource "random_pet" "this" {
  length = 1
}

module "s3_bucket" {
  source                   = "gitlab.nexdev.net/iac-terraform/aws-s3/aws"
  version                  = "3.15.1"
  bucket                   = "data-backup-${var.environment}-${random_pet.this.id}"
  acl                      = "private"
  attach_policy            = true
  policy                   = data.aws_iam_policy_document.bucket_policy.json
  control_object_ownership = true
  # object_ownership         = "BucketOwnerPreferred"
  object_ownership = "BucketOwnerEnforced"

  versioning = {
    enabled = false
  }
  tags = merge(
    local.common_tags,
    {
      Resource = "S3"
    },
  )
}

#######################
resource "aws_iam_role" "this" {
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

#################################

data "aws_iam_policy_document" "bucket_policy" {
  statement {
    sid = "ListObjectsInBucket"
    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = [
      "s3:ListBucket"
    ]

    resources = [
      "arn:aws:s3:::data-backup-${var.environment}-${random_pet.this.id}",
    ]

    condition {
      test     = "IpAddress"
      variable = "aws:SourceIp"
      values   = var.ingress_cidr_blocks
      /*[
      "202.78.231.32/27",
      "120.72.109.32/29",
      "120.72.83.128/29"
      ]*/
    }

  }

  statement {
    sid = "AllObjectActions"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions = [
      "s3:*Object*"
    ]

    resources = [
      "arn:aws:s3:::data-backup-${var.environment}-${random_pet.this.id}/*",
    ]

    condition {
      test     = "IpAddress"
      variable = "aws:SourceIp"
      values   = var.ingress_cidr_blocks
    }
  }
}
