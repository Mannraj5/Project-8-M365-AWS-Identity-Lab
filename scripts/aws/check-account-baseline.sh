#!/usr/bin/env bash
# SC2015: pass() only prints, so "A && pass || flag" cannot run both.
# SC2016: backticks inside --query are JMESPath literals, not shell.
# shellcheck disable=SC2015,SC2016
# Phase 6 acceptance checks for the management account. Read-only.
#   - root user has MFA and no access keys
#   - a budget exists
#   - the credential report shows no human IAM users (only the root row)
#   - an organisation CloudTrail trail is logging
#
# Usage: AWS_PROFILE=lab-mgmt ./check-account-baseline.sh
set -euo pipefail

fail=0
pass() { printf 'PASS  %s\n' "$1"; }
flag() { printf 'FAIL  %s\n' "$1"; fail=1; }

account_id=$(aws sts get-caller-identity --query Account --output text)
echo "Account: ****${account_id: -4}"

# --- Root user -------------------------------------------------------------
summary=$(aws iam get-account-summary --output json)
[[ $(jq -r '.SummaryMap.AccountMFAEnabled' <<<"$summary") == 1 ]] \
  && pass "root MFA enabled" || flag "root MFA NOT enabled"
[[ $(jq -r '.SummaryMap.AccountAccessKeysPresent' <<<"$summary") == 0 ]] \
  && pass "root has no access keys" || flag "root HAS access keys"

# --- Budget ----------------------------------------------------------------
budgets=$(aws budgets describe-budgets --account-id "$account_id" \
  --query 'length(Budgets || `[]`)' --output text 2>/dev/null || echo 0)
[[ $budgets -ge 1 ]] && pass "$budgets budget(s) configured" || flag "no budget configured"

# --- Credential report -----------------------------------------------------
# generate-credential-report is asynchronous; poll until it is COMPLETE.
for _ in {1..10}; do
  state=$(aws iam generate-credential-report --query State --output text)
  [[ $state == COMPLETE ]] && break
  sleep 2
done
report=$(aws iam get-credential-report --query Content --output text | base64 --decode)
# Row 1 is the header, row 2 is <root_account>; anything else is an IAM user.
iam_users=$(tail -n +2 <<<"$report" | grep -vc '^<root_account>' || true)
if [[ $iam_users -eq 0 ]]; then
  pass "credential report: no IAM users"
else
  flag "credential report: $iam_users IAM user(s):"
  tail -n +2 <<<"$report" | grep -v '^<root_account>' \
    | awk -F, '{printf "        %s  password_enabled=%s  key1_active=%s  key2_active=%s\n",$1,$4,$9,$14}'
fi

# --- CloudTrail ------------------------------------------------------------
org_trails=$(aws cloudtrail describe-trails \
  --query 'trailList[?IsOrganizationTrail==`true`].TrailARN' --output text)
if [[ -z $org_trails ]]; then
  flag "no organisation trail"
else
  for arn in $org_trails; do
    logging=$(aws cloudtrail get-trail-status --name "$arn" --query IsLogging --output text)
    [[ $logging == True ]] && pass "org trail logging: ${arn##*/}" || flag "org trail NOT logging: ${arn##*/}"
  done
fi

exit $fail
