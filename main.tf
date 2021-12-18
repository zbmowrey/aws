terraform {
  backend "remote" {
    organization = "zbmowrey-cloud-admin"

    workspaces {
      name = "cloud-admin"
    }
  }
}

# Default provider & "virginia" provider to specify us-east-1.

provider "aws" {
  region = var.region
}
provider "aws" {
  alias  = "virginia"
  region = "us-east-1"
}

locals {
  app_accounts = toset([
    "Development",
    "Production",
    "Staging",
    "Deployment",
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
  enabled_policy_types          = [
    "SERVICE_CONTROL_POLICY"
  ]
}

## Organizational Units ########################################

resource "aws_organizations_organizational_unit" "AppAccounts" {
  name      = "AppAccounts"
  parent_id = aws_organizations_organization.root.id
  tags      = {
    CostCenter  = "Applications"
    Environment = "all"
  }
}

resource "aws_organizations_organizational_unit" "SCPSandbox" {
  name      = "SCPSandbox"
  parent_id = aws_organizations_organization.root.id
  tags      = {
    CostCenter  = "Applications"
    Environment = "all"
  }
}

resource "aws_organizations_organizational_unit" "RecycleBin" {
  name      = "RecycleBin"
  parent_id = aws_organizations_organization.root.id
  tags      = {
    CostCenter  = "Internal - Management"
    Environment = "Recycle"
  }
}

## Service Control Policies (SCP) ##############################

resource "aws_organizations_policy" "no_access" {
  name        = "no_access"
  description = "For accounts that can't be closed, this prevents them from being used for any purpose."
  tags        = {
    CostCenter  = "Internal - Management"
    Environment = "Production"
  }
  content     = <<CONTENT
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
  name    = "full_access"
  tags    = {
    CostCenter  = "Internal - Management"
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

resource "aws_organizations_policy" "app_access" {
  name = "app_access"
  tags = {
    CostCenter  = "Internal - Management"
    Environment = "Production"
  }

  content = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      # Prevent anyone from accessing the root user of a sub-account.
      {
        Sid       = "DenyRootUser"
        Effect    = "Deny"
        Action    = "*"
        Resource  = "*"
        Condition = {
          StringLike = {
            "aws:PrincipalArn" : "arn:aws:iam::*:root"
          }
        }
      },
      # Prevent anyone from modifying the OrganizationAccountAccessRole, ensuring that
      # Org admins can always access child accounts.
      {
        Sid       = "PreserveCriticalRoles"
        Effect    = "Deny"
        NotAction = [
          "iam:GetContextKeysForPrincipalPolicy",
          "iam:GetRole",
          "iam:GetRolePolicy",
          "iam:ListAttachedRolePolicies",
          "iam:ListInstanceProfilesForRole",
          "iam:ListRolePolicies",
          "iam:ListRoleTags",
          "iam:SimulatePrincipalPolicy",
        ]
        Resource  = [
          "arn:aws:iam::*:role/AdminRole",
          "arn:aws:iam::*:role/OrganizationAccountAccessRole",
        ]
      },
      # Allow a list of services necessary for normal operations. This will need to be
      # tweaked as applications evolve.
      {
        Sid      = "AllowedServicesList"
        Effect   = "Allow"
        Resource = "*"
        Action   = [
          #"a4b:*",
          "access-analyzer:*",
          "account:*",
          "acm:*",
          "acm-pca:*",
          #"amplify:*",
          "apigateway:*",
          #"application-autoscaling:*",
          #"applicationinsights:*",
          #"appmesh:*",
          #"appmesh-preview:*",
          #"appstream:*",
          #"appsync:*",
          #"arsenal:*",
          #"artifact:*",
          #"athena:*",
          #"autoscaling:*",
          #"autoscaling-plans:*",
          #"aws-marketplace:*",
          #"aws-marketplace-management:*",
          #"aws-portal:*",
          #"backup:*",
          #"backup-storage:*",
          #"batch:*",
          "budgets:*",
          #"cassandra:*",
          #"ce:*",
          #"chatbot:*",
          #"chime:*",
          #"cloud9:*",
          #"clouddirectory:*",
          "cloudformation:*",
          "cloudfront:*",
          #"cloudhsm:*",
          #"cloudsearch:*",
          "cloudtrail:*",
          "cloudwatch:*",
          "codebuild:*",
          "codecommit:*",
          "codedeploy:*",
          #"codeguru-profiler:*",
          #"codeguru-reviewer:*",
          "codepipeline:*",
          #"codestar:*",
          #"codestar-notifications:*",
          "cognito-identity:*",
          "cognito-idp:*",
          "cognito-sync:*",
          #"comprehend:*",
          #"comprehendmedical:*",
          #"compute-optimizer:*",
          "config:*",
          #"connect:*",
          "cur:*",
          #"dataexchange:*",
          #"datapipeline:*",
          #"datasync:*",
          #"dax:*",
          #"dbqms:*",
          #"deeplens:*",
          #"deepracer:*",
          #"detective:*",
          #"devicefarm:*",
          #"directconnect:*",
          #"discovery:*",
          #"dlm:*",
          #"dms:*",
          #"ds:*",
          "dynamodb:*",
          #"ebs:*",
          #"ec2:*",
          #"ec2-instance-connect:*",
          #"ec2messages:*",
          #"ecr:*",
          #"ecs:*",
          #"eks:*",
          #"elastic-inference:*",
          #"elasticache:*",
          #"elasticbeanstalk:*",
          #"elasticfilesystem:*",
          #"elasticloadbalancing:*",
          #"elasticmapreduce:*",
          #"elastictranscoder:*",
          #"es:*",
          "events:*",
          "execute-api:*",
          #"firehose:*",
          #"fms:*",
          #"forecast:*",
          #"frauddetector:*",
          #"freertos:*",
          #"fsx:*",
          #"gamelift:*",
          "glacier:*",
          #"globalaccelerator:*",
          #"glue:*",
          #"greengrass:*",
          #"groundstation:*",
          #"groundtruthlabeling:*",
          #"guardduty:*",
          #"health:*",
          "iam:*",
          #"imagebuilder:*",
          #"importexport:*",
          #"inspector:*",
          #"iot:*",
          #"iot-device-tester:*",
          #"iot1click:*",
          #"iotanalytics:*",
          #"iotevents:*",
          #"iotsitewise:*",
          #"iotthingsgraph:*",
          #"kafka:*",
          #"kendra:*",
          "kinesis:*",
          #"kinesisanalytics:*",
          #"kinesisvideo:*",
          "kms:*",
          #"lakeformation:*",
          "lambda:*",
          #"launchwizard:*",
          #"lex:*",
          #"license-manager:*",
          #"lightsail:*",
          "logs:*",
          #"machinelearning:*",
          #"macie:*",
          #"managedblockchain:*",
          #"mechanicalturk:*",
          #"mediaconnect:*",
          #"mediaconvert:*",
          #"medialive:*",
          #"mediapackage:*",
          #"mediapackage-vod:*",
          #"mediastore:*",
          #"mediatailor:*",
          #"mgh:*",
          #"mobileanalytics:*",
          #"mobilehub:*",
          #"mobiletargeting:*",
          #"mq:*",
          #"neptune-db:*",
          "networkmanager:*",
          #"opsworks:*",
          #"opsworks-cm:*",
          "organizations:*",
          #"outposts:*",
          #"personalize:*",
          #"pi:*",
          #"polly:*",
          #"pricing:*",
          #"qldb:*",
          #"quicksight:*",
          #"ram:*",
          "rds:*",
          "rds-data:*",
          "rds-db:*",
          "redshift:*",
          #"rekognition:*",
          #"resource-groups:*",
          #"robomaker:*",
          "route53:*",
          "route53domains:*",
          "route53resolver:*",
          "s3:*",
          #"sagemaker:*",
          "savingsplans:*",
          #"schemas:*",
          #"sdb:*",
          "secretsmanager:*",
          #"securityhub:*",
          "serverlessrepo:*",
          "servicecatalog:*",
          "servicediscovery:*",
          "servicequotas:*",
          "ses:*",
          #"shield:*",
          #"signer:*",
          #"sms:*",
          #"sms-voice:*",
          #"snowball:*",
          "sns:*",
          "sqs:*",
          "ssm:*",
          "ssmmessages:*",
          "sso:*",
          "sso-directory:*",
          "states:*",
          #"storagegateway:*",
          "sts:*",
          #"sumerian:*",
          "support:*",
          "swf:*",
          #"synthetics:*",
          "tag:*",
          #"textract:*",
          #"transcribe:*",
          #"transfer:*",
          #"translate:*",
          "trustedadvisor:*",
          "waf:*",
          "waf-regional:*",
          "wafv2:*",
          #"wam:*",
          "wellarchitected:*",
          #"workdocs:*",
          #"worklink:*",
          #"workmail:*",
          #"workmailmessageflow:*",
          #"workspaces:*",
          "xray:*"
        ]
      }
    ]
  })
}

## Service Control Policy Attachments ##########################

resource "aws_organizations_policy_attachment" "root_full_access" {
  policy_id = aws_organizations_policy.full_access.id
  target_id = aws_organizations_organization.root.id
}

resource "aws_organizations_policy_attachment" "app_access" {
  policy_id = aws_organizations_policy.app_access.id
  target_id = aws_organizations_organizational_unit.AppAccounts.id
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
    CostCenter  = "Internal - Management"
    Environment = "Production"
  }
}

## App Accounts ################################################

resource "aws_organizations_account" "app_accounts" {
  for_each  = local.app_accounts
  email     = join("", [join("-", ["aws", lower(each.value)]), var.account_email_domain])
  name      = each.value
  parent_id = aws_organizations_organizational_unit.AppAccounts.id
  tags      = {
    CostCenter  = join(" - ", ["Applications", each.value])
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
  provider = aws.virginia

  report_name = "aws-hourly-cost-usage-report"
  s3_bucket   = aws_s3_bucket.cur-report.bucket
  s3_region   = "us-east-1"

  time_unit         = "HOURLY"
  report_versioning = "OVERWRITE_REPORT"
  format            = "textORcsv"
  compression       = "GZIP"

  additional_schema_elements = ["RESOURCES"]
}
