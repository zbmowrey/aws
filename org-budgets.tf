# Create organization-level budgets & alerts to prevent unintentional overspend.

locals {
  notify_emails = ["zb@zbmowrey.com", "zbmowrey@gmail.com"]

  # the expected monthly maximum spend.
  budget = 100

  # percentages that will trigger email notification
  thresholds = [5, 10, 25, 50, 100, 200, 400, 600, 800, 1000]
}

resource "aws_budgets_budget" "overall" {
  name              = "OverallBudget"
  budget_type       = "COST"
  limit_amount      = local.budget
  limit_unit        = "USD"
  time_period_end   = "2087-06-15_00:00"
  time_unit         = "MONTHLY"

  # I want to receive a stream of emails as my budget passes various milestones,
  # with the last several (200% and above) acting as emergency brakes on a bill
  # that has gone out of control for some reason. Under normal circumstances, I'd
  # never go over the limit_amount in a month. If this changes, the value should
  # be updated to remain in sync with expectations.

  dynamic "notification" {
    for_each = local.thresholds
    content {
      comparison_operator        = "GREATER_THAN"
      threshold                  = notification.value
      threshold_type             = "PERCENTAGE"
      notification_type          = "FORECASTED"
      subscriber_email_addresses = local.notify_emails
    }
  }
}