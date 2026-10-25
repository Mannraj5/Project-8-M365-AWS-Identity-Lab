#!/usr/bin/env bash
# Phase 6 evidence: recent IAM Identity Center sign-ins and role federation
# from CloudTrail event history (last 90 days, management events).
#
# Run it in the region where IAM Identity Center is enabled.
# Usage: AWS_PROFILE=lab-mgmt AWS_REGION=ap-southeast-2 ./find-signin-events.sh [hours-back]
set -euo pipefail

hours=${1:-24}
start=$(date -u -d "-${hours} hours" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null \
  || date -u -v-"${hours}"H +%Y-%m-%dT%H:%M:%SZ)   # GNU date, then BSD/macOS date

for source in signin.amazonaws.com sso.amazonaws.com; do
  echo "== $source since $start"
  aws cloudtrail lookup-events \
    --lookup-attributes "AttributeKey=EventSource,AttributeValue=$source" \
    --start-time "$start" --max-results 50 \
    --query 'Events[].[EventTime,EventName,Username]' --output table
done
