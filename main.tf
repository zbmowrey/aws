terraform {
  backend "remote" {
    organization = "zbmowrey-cloud-admin"

    workspaces {
      name = "cloud-admin"
    }
  }
}

provider "aws" {
  region = var.region
}
provider "aws" {
  alias = "virginia"
  region = "us-east-1"
}

locals {
  app_accounts = toset([
    "Development",
    "Production",
    "Staging"
  ])
}

## Organizations ###############################################

resource "aws_organizations_organization" "root" {
  aws_service_access_principals = [
    "config.amazonaws.com",
    "controltower.amazonaws.com",
    "member.org.stacksets.cloudformation.amazonaws.com",
    "sso.amazonaws.com"
  ]
  enabled_policy_types = [
    "SERVICE_CONTROL_POLICY"
  ]
}

## Organizational Units ########################################

resource "aws_organizations_organizational_unit" "AppAccounts" {
  name      = "AppAccounts"
  parent_id = aws_organizations_organization.root.id
  tags = {
    CostCenter = "Applications"
    Environment = "all"
  }
}

resource "aws_organizations_organizational_unit" "RecycleBin" {
  name      = "RecycleBin"
  parent_id = aws_organizations_organization.root.id
  tags = {
    CostCenter = "Internal - Management"
    Environment = "Recycle"
  }
}

## Service Control Policies (SCP) ##############################

resource "aws_organizations_policy" "no_access" {
  name = "no_access"
  description = "For accounts that can't be closed, this prevents them from being used for any purpose."
  tags = {
    CostCenter = "Internal - Management"
    Environment = "Production"
  }
  content = <<CONTENT
{
  "Version": "2012-10-17",
  "Statement": [{
    "Action": [
        "*"
    ],
    "Effect": "Deny",
    "Resource": "*",
    "Sid": "VisualEditor0"
  }]
}
CONTENT
}

resource "aws_organizations_policy" "full_access" {
  name = "full_access"
  tags = {
    CostCenter = "Internal - Management"
    Environment = "Production"
  }
  content = <<CONTENT
{
  "Version": "2012-10-17",
  "Statement": {
    "Effect": "Allow",
    "Action": "*",
    "Resource": "*"
  }
}
CONTENT
}

## Service Control Policy Attachments ##########################

resource "aws_organizations_policy_attachment" "root_full_access" {
  policy_id = aws_organizations_policy.full_access.id
  target_id = aws_organizations_organization.root.id
}

resource "aws_organizations_policy_attachment" "no_access" {
  policy_id = aws_organizations_policy.no_access.id
  target_id = aws_organizations_organizational_unit.RecycleBin.id
}

## Root Account ################################################

resource "aws_organizations_account" "root" {
  email = var.root_account_email
  name  = var.root_account_name
  tags  = {
    CostCenter = "Internal - Management"
    Environment = "Production"
  }
}

## App Accounts ################################################

resource "aws_organizations_account" "app_accounts" {
  for_each = local.app_accounts
  email    = join("",[join("-",["aws",lower(each.value)]),var.account_email_domain])
  name     = each.value
  parent_id = aws_organizations_organizational_unit.AppAccounts.id
  tags = {
    CostCenter = join(" - ",["Applications",each.value])
    Environment = each.value
  }
}

## Cost & Usage Report #########################################

resource "aws_s3_bucket" "cur-report" {
  provider = aws.virginia
  bucket   = "zbm-cost-usage-reports"
  policy   = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "billingreports.amazonaws.com"
      },
      "Action": [
        "s3:GetBucketAcl",
        "s3:GetBucketPolicy"
      ],
      "Resource": "arn:aws:s3:::zbm-cost-usage-reports"
    },
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "billingreports.amazonaws.com"
      },
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::zbm-cost-usage-reports/*"
    }
  ]
}
POLICY
}

resource "aws_cur_report_definition" "report" {
  provider                   = aws.virginia

  report_name                = "aws-hourly-cost-usage-report"
  s3_bucket                  = aws_s3_bucket.cur-report.bucket
  s3_region                  = "us-east-1"

  time_unit                  = "HOURLY"
  report_versioning          = "OVERWRITE_REPORT"
  format                     = "textORcsv"
  compression                = "GZIP"

  additional_schema_elements = ["RESOURCES"]
}