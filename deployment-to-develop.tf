provider "aws" {
  alias  = "develop"
  region = var.region
  default_tags {
    tags = local.default_tags
  }
  assume_role {
    role_arn = "arn:aws:iam::${var.develop_account_id}:role/OrganizationAccountAccessRole"
  }
}

resource "aws_iam_role" "develop-allow-deployment" {
  provider           = aws.develop
  name               = "ApplicationDeployment"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Action    = "sts:AssumeRole",
        Principal = { "AWS" : "arn:aws:iam::${var.deployment_account_id}:root" }
      },
      {
        "Sid" : "AllowPassSessionTags",
        "Effect" : "Allow",
        "Action" : "sts:TagSession",
        "Principal" : { "AWS" : "arn:aws:iam::${var.deployment_account_id}:root" },
      }
    ]
  })
}

resource "aws_iam_policy" "develop-deployment-permissions" {
  provider    = aws.develop
  name        = "ApplicationDeployment"
  description = "Permissions necessary for deployment of infrastructure into Develop Account."
  policy      = file("deployment-policy.json")
}

resource "aws_iam_policy_attachment" "develop-deployment-permissions" {
  provider   = aws.develop
  name       = "Allowed Infrastructure Deployment"
  roles      = [aws_iam_role.develop-allow-deployment.name]
  policy_arn = aws_iam_policy.develop-deployment-permissions.arn
}

# Github Open ID Connector - Allow Github to directly connect to Develop without using secrets.

module "github-oidc-develop" {
  providers = {
    aws = aws.develop
  }
  source    = "registry.terraform.io/unfunco/oidc-github/aws"
  version   = "0.4.0"

  github_organisation = "zbmowrey"
  github_repositories = ["zbmowrey-com", "repsales-net", "tomatowarning-com"]
  iam_role_name       = "GithubDeploymentRole"
  attach_admin_policy = true
}

# CloudTrail Trail & Bucket

module "audit-events-cloudtrail-bucket-develop" {
  providers                = {
    aws = aws.develop
  }
  source                   = "registry.terraform.io/cloudposse/cloudtrail-s3-bucket/aws"
  acl                      = "log-delivery-write"
  namespace                = "zbmowrey"
  environment              = "develop"
  name                     = "audit-events"
}

module "audit-events-cloudtrail-develop" {
  providers                     = {
    aws = aws.develop
  }
  source                        = "registry.terraform.io/cloudposse/cloudtrail/aws"
  s3_bucket_name                = module.audit-events-cloudtrail-bucket-develop.bucket_id
  is_multi_region_trail         = true
  include_global_service_events = true
  name                          = "audit-events"
}