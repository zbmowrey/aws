provider "aws" {
  alias  = "staging"
  region = var.region
  default_tags {
    tags = local.default_tags
  }
  assume_role {
    role_arn = "arn:aws:iam::${var.staging_account_id}:role/OrganizationAccountAccessRole"
  }
}

resource "aws_iam_role" "staging-allow-deployment" {
  provider           = aws.staging
  name               = "ApplicationDeployment"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Action    = "sts:AssumeRole",
        Principal = { "AWS" : "arn:aws:iam::${var.deployment_account_id}:root" }
      }
    ]
  })
}

resource "aws_iam_policy" "staging-deployment-permissions" {
  provider    = aws.staging
  name        = "ApplicationDeployment"
  description = "Permissions necessary for deployment of infrastructure into Develop Account."
  policy      = file("deployment-policy.json")
}

resource "aws_iam_policy_attachment" "staging-deployment-permissions" {
  provider   = aws.staging
  name       = "Allowed Infrastructure Deployment"
  roles      = [aws_iam_role.staging-allow-deployment.name]
  policy_arn = aws_iam_policy.staging-deployment-permissions.arn
}