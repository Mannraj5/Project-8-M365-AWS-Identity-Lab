#!/usr/bin/env bash
# Phase 6 evidence: what IAM Identity Center holds after SCIM provisioning.
# Lists users, groups with member counts, permission sets, and which group
# has which permission set in which account. Read-only.
#
# Usage: AWS_PROFILE=lab-mgmt ./check-identity-center.sh
set -euo pipefail

read -r instance_arn store_id < <(aws sso-admin list-instances \
  --query 'Instances[0].[InstanceArn,IdentityStoreId]' --output text) || true
[[ -z ${instance_arn:-} || $instance_arn == None ]] && { echo "IAM Identity Center is not enabled."; exit 1; }

echo "== Users (provisioned by SCIM)"
aws identitystore list-users --identity-store-id "$store_id" \
  --query 'Users[].[UserName,DisplayName]' --output table

echo "== Groups"
declare -A group_name
while read -r gid gname; do
  group_name[$gid]=$gname
  count=$(aws identitystore list-group-memberships --identity-store-id "$store_id" \
    --group-id "$gid" --query 'length(GroupMemberships)' --output text)
  printf '  %-22s %s member(s)\n' "$gname" "$count"
done < <(aws identitystore list-groups --identity-store-id "$store_id" \
  --query 'Groups[].[GroupId,DisplayName]' --output text)

echo "== Assignments (permission set -> account -> principal)"
declare -A account_name
while read -r aid aname; do account_name[$aid]=$aname; done < <(
  aws organizations list-accounts --query 'Accounts[].[Id,Name]' --output text)

for ps in $(aws sso-admin list-permission-sets --instance-arn "$instance_arn" --query 'PermissionSets[]' --output text); do
  ps_name=$(aws sso-admin describe-permission-set --instance-arn "$instance_arn" \
    --permission-set-arn "$ps" --query 'PermissionSet.Name' --output text)
  accounts=$(aws sso-admin list-accounts-for-provisioned-permission-set \
    --instance-arn "$instance_arn" --permission-set-arn "$ps" --query 'AccountIds[]' --output text)
  [[ -z $accounts ]] && { printf '  %-12s (not assigned)\n' "$ps_name"; continue; }
  for acct in $accounts; do
    aws sso-admin list-account-assignments --instance-arn "$instance_arn" \
      --account-id "$acct" --permission-set-arn "$ps" \
      --query 'AccountAssignments[].[PrincipalType,PrincipalId]' --output text |
    while read -r ptype pid; do
      who=${group_name[$pid]:-$pid}
      printf '  %-12s %-12s %s %s\n' "$ps_name" "${account_name[$acct]:-$acct}" "$ptype" "$who"
    done
  done
done
