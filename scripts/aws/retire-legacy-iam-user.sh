#!/usr/bin/env bash
# Phase 6: retire a long-lived IAM user, one documented step at a time.
#
#   ./retire-legacy-iam-user.sh <user> inspect     show keys, last use, groups, policies
#   ./retire-legacy-iam-user.sh <user> deactivate  set every access key Inactive (reversible)
#   ./retire-legacy-iam-user.sh <user> delete      remove everything attached, then the user
#
# Leave time between deactivate and delete (a day in real life) so anything
# that still used the key fails loudly and can be found, while the change is
# still reversible. Record each step's output in evidence/test-results.md.
set -euo pipefail

user=${1:?usage: $0 <iam-user> inspect|deactivate|delete}
action=${2:-inspect}

keys() { aws iam list-access-keys --user-name "$user" --query 'AccessKeyMetadata[].AccessKeyId' --output text; }

case $action in
  inspect)
    echo "== Access keys"
    for k in $(keys); do
      status=$(aws iam list-access-keys --user-name "$user" \
        --query "AccessKeyMetadata[?AccessKeyId=='$k'].Status" --output text)
      last=$(aws iam get-access-key-last-used --access-key-id "$k" \
        --query 'AccessKeyLastUsed.[LastUsedDate,ServiceName,Region]' --output text)
      echo "  ****${k: -4}  $status  last used: $last"
    done
    echo "== Groups";           aws iam list-groups-for-user        --user-name "$user" --query 'Groups[].GroupName'       --output text
    echo "== Attached policies"; aws iam list-attached-user-policies --user-name "$user" --query 'AttachedPolicies[].PolicyName' --output text
    echo "== Inline policies";   aws iam list-user-policies          --user-name "$user" --query 'PolicyNames[]'            --output text
    echo "== Console password"
    aws iam get-login-profile --user-name "$user" >/dev/null 2>&1 && echo "  yes" || echo "  no"
    ;;

  deactivate)
    for k in $(keys); do
      aws iam update-access-key --user-name "$user" --access-key-id "$k" --status Inactive
      echo "Deactivated key ****${k: -4}"
    done
    ;;

  delete)
    read -r -p "Permanently delete IAM user '$user'? Type the user name to confirm: " answer
    [[ $answer == "$user" ]] || { echo "Aborted."; exit 1; }

    for k in $(keys); do aws iam delete-access-key --user-name "$user" --access-key-id "$k"; echo "Deleted key ****${k: -4}"; done
    aws iam delete-login-profile --user-name "$user" 2>/dev/null && echo "Deleted console password" || true
    for p in $(aws iam list-user-policies --user-name "$user" --query 'PolicyNames[]' --output text); do
      aws iam delete-user-policy --user-name "$user" --policy-name "$p"; echo "Deleted inline policy $p"
    done
    for p in $(aws iam list-attached-user-policies --user-name "$user" --query 'AttachedPolicies[].PolicyArn' --output text); do
      aws iam detach-user-policy --user-name "$user" --policy-arn "$p"; echo "Detached ${p##*/}"
    done
    for g in $(aws iam list-groups-for-user --user-name "$user" --query 'Groups[].GroupName' --output text); do
      aws iam remove-user-from-group --user-name "$user" --group-name "$g"; echo "Removed from group $g"
    done
    for m in $(aws iam list-mfa-devices --user-name "$user" --query 'MFADevices[].SerialNumber' --output text); do
      aws iam deactivate-mfa-device --user-name "$user" --serial-number "$m"
      aws iam delete-virtual-mfa-device --serial-number "$m" 2>/dev/null || true
      echo "Removed MFA device"
    done
    for c in $(aws iam list-signing-certificates --user-name "$user" --query 'Certificates[].CertificateId' --output text); do
      aws iam delete-signing-certificate --user-name "$user" --certificate-id "$c"
    done
    for s in $(aws iam list-ssh-public-keys --user-name "$user" --query 'SSHPublicKeys[].SSHPublicKeyId' --output text); do
      aws iam delete-ssh-public-key --user-name "$user" --ssh-public-key-id "$s"
    done
    aws iam delete-user --user-name "$user"
    echo "Deleted IAM user $user. Re-run check-account-baseline.sh to confirm the credential report is clean."
    ;;

  *) echo "Unknown action: $action"; exit 2 ;;
esac
