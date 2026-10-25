#!/usr/bin/env bash
# Day-one cost guardrail: a monthly cost budget with email alerts at 80% of
# actual spend and 100% of forecast spend. Budget amount is in config/aws/budget.json.
#
# Usage: AWS_PROFILE=lab-mgmt ./create-budget.sh you@example.com
set -euo pipefail

email=${1:?usage: $0 <alert-email>}
here=$(cd "$(dirname "$0")" && pwd)
budget_file="$here/../../config/aws/budget.json"
account_id=$(aws sts get-caller-identity --query Account --output text)

notifications=$(jq -n --arg email "$email" '[
  { Notification: { NotificationType: "ACTUAL",     ComparisonOperator: "GREATER_THAN", Threshold: 80,  ThresholdType: "PERCENTAGE" },
    Subscribers: [ { SubscriptionType: "EMAIL", Address: $email } ] },
  { Notification: { NotificationType: "FORECASTED", ComparisonOperator: "GREATER_THAN", Threshold: 100, ThresholdType: "PERCENTAGE" },
    Subscribers: [ { SubscriptionType: "EMAIL", Address: $email } ] }
]')

aws budgets create-budget \
  --account-id "$account_id" \
  --budget "file://$budget_file" \
  --notifications-with-subscribers "$notifications"

echo "Created budget $(jq -r .BudgetName "$budget_file") ($(jq -r '.BudgetLimit | "\(.Amount) \(.Unit)"' "$budget_file")/month)."
