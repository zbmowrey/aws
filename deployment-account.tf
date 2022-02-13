provider "aws" {
  alias   = "deployment"
  region  = var.region
  profile = "org"
  default_tags {
    tags = local.default_tags
  }
  assume_role {
    role_arn = "arn:aws:iam::${var.deployment_account_id}:role/OrganizationAccountAccessRole"
  }
}

resource "aws_iam_user" "deployment" {
  provider = aws.deployment
  name     = "deployment"
}

resource "aws_iam_policy" "deploy-assume-develop-role" {
  provider    = aws.deployment
  name        = "DeploymentIntoDevelop"
  description = "Allow Assumption of ApplicationDeployment in Develop Account"
  policy      = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "sts:AssumeRole",
        Resource = [
          "arn:aws:iam::${var.develop_account_id}:role/${aws_iam_role.develop-allow-deployment.name}",
          "arn:aws:iam::${var.staging_account_id}:role/${aws_iam_role.staging-allow-deployment.name}",
          "arn:aws:iam::${var.main_account_id}:role/${aws_iam_role.main-allow-deployment.name}"
        ]
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "deployment-policy" {
  provider   = aws.deployment
  user       = aws_iam_user.deployment.name
  policy_arn = aws_iam_policy.deploy-assume-develop-role.arn
}