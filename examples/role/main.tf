terraform {
  required_version = ">= 0.13.1"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.9.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.4.3"
    }
  }
}

provider "aws" {
  region = "eu-west-1"
}

locals {
  tags = {
    uasage = "clickops-testing"
    run    = random_pet.run_id.id
  }

  naming_prefix = "clickops-test-role-${random_pet.run_id.id}"
}

resource "random_pet" "run_id" {
  keepers = {
    # Generate a new pet name each time we switch to a new AMI id
    run_id = var.run_id
  }
}

module "clickops_notifications" {
  source = "../../"

  naming_prefix          = local.naming_prefix
  cloudtrail_bucket_name = aws_s3_bucket.test_bucket.id
  webhook                = "https://fake.com"
  message_format         = "slack"
  tags                   = local.tags

  create_iam_role = false
  iam_role_arn    = aws_iam_role.test_role.arn
}

resource "aws_iam_role" "test_role" {
  name = local.naming_prefix

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "test_attach" {
  role       = aws_iam_role.test_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSQSFullAccess"
}



resource "aws_s3_bucket" "test_bucket" {
  bucket = local.naming_prefix
  tags   = local.tags
}
