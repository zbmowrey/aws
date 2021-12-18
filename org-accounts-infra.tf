# Deploy standardized infrastructure to sub-accounts within the Organization.
# Terraform State (s3/dynamo) is my entry point, but I'm also considering
# uniform IAM roles and other governance-related items.

provider "aws" {
  alias = "develop"
  region = var.region
  assume_role {
    role_arn = var.develop_assume_role
  }
}
provider "aws" {
  alias = "staging"
  region = var.region
  assume_role {
    role_arn = var.staging_assume_role
  }
}
provider "aws" {
  alias = "main"
  region = var.region
  assume_role {
    role_arn = var.main_assume_role
  }
}

# Create a dynamo table for terraform locks in each of the environment accounts.

resource "aws_dynamodb_table" "governance-terraform-locks" {
  hash_key = "LockID"
  name     = "terraform-locks"
  attribute {
    name = "LockID"
    type = "S"
  }
  tags = {
    CostCenter = "zbmowrey-global"
  }
  billing_mode = "PAY_PER_REQUEST"
}

resource "aws_s3_bucket" "governance-tf-state" {
  bucket = "zbm-governance-terraform-state"
}

resource "aws_dynamodb_table" "develop-terraform-locks" {
  provider = aws.develop
  hash_key = "LockID"
  name     = "terraform-locks"
  attribute {
    name = "LockID"
    type = "S"
  }
  tags = {
    CostCenter = "zbmowrey-global"
  }
  billing_mode = "PAY_PER_REQUEST"
}

resource "aws_s3_bucket" "develop-tf-state" {
  bucket = "zbm-develop-terraform-state"
}

resource "aws_dynamodb_table" "staging-terraform-locks" {
  provider = aws.staging
  hash_key = "LockID"
  name     = "terraform-locks"
  attribute {
    name = "LockID"
    type = "S"
  }
  tags = {
    CostCenter = "zbmowrey-global"
  }
  billing_mode = "PAY_PER_REQUEST"
}

resource "aws_s3_bucket" "staging-tf-state" {
  bucket = "zbm-staging-terraform-state"
}

resource "aws_dynamodb_table" "main-terraform-locks" {
  provider = aws.main
  hash_key = "LockID"
  name     = "terraform-locks"
  attribute {
    name = "LockID"
    type = "S"
  }
  tags = {
    CostCenter = "zbmowrey-global"
  }
  billing_mode = "PAY_PER_REQUEST"
}

resource "aws_s3_bucket" "main-tf-state" {
  bucket = "zbm-main-terraform-state"
}