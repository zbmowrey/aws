# We use EventBridge to send specific CloudTrail API Calls for all sub-accounts to a specific audit account,
# where we can fan out based on centralized rules.

resource "aws_cloudwatch_event_bus" "audit-events" {
  name = "audit-events"
}

# A CloudTrail Trail is required for EventBridge to listen for CloudTrail API events.

module "audit-events-cloudtrail-bucket-root" {
  source                   = "registry.terraform.io/cloudposse/cloudtrail-s3-bucket/aws"
  acl                      = "log-delivery-write"
  namespace                = "zbm"
  name                     = "audit-events"
}

module "audit-events-cloudtrail-root" {
  source                        = "registry.terraform.io/cloudposse/cloudtrail/aws"
  s3_bucket_name                = module.audit-events-cloudtrail-bucket-root.bucket_id
  is_multi_region_trail         = true
  include_global_service_events = true
  namespace                     = "zbm"
  name                          = "audit-events"
}

# Create the target "proof it works" queue.

resource "aws_sqs_queue" "audit-events" {
  name = "audit-events"
}

# Create a policy to allow other accounts to PUT events into our custom bus.

data "aws_iam_policy_document" "audit-events" {

  statement {
    sid       = "AllowPutEvents"
    effect    = "Allow"
    actions   = [
      "events:PutEvents",
    ]
    resources = [
      aws_cloudwatch_event_bus.audit-events.arn
    ]

    principals {
      type        = "AWS"
      identifiers = [for acct in aws_organizations_account.app_accounts : acct.id]
    }
  }

  statement {
    sid       = "AllowUpdateRules"
    effect    = "Allow"
    actions   = [
      "events:PutRule",
      "events:PutTargets",
      "events:DeleteRule",
      "events:RemoveTargets",
      "events:DisableRule",
      "events:EnableRule",
      "events:TagResource",
      "events:UntagResource",
      "events:DescribeRule",
      "events:ListTargetsByRule",
      "events:ListTagsForResource"
    ]
    resources = [
      aws_cloudwatch_event_bus.audit-events.arn
    ]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalOrgID"
      values   = [aws_organizations_organization.root.id]
    }
  }
}

resource "aws_cloudwatch_event_bus_policy" "audit-events" {
  policy         = data.aws_iam_policy_document.audit-events.json
  event_bus_name = aws_cloudwatch_event_bus.audit-events.name
}