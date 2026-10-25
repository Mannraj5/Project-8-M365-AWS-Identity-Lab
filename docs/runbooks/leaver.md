# Runbook: Leaver

**Trigger:** resignation or termination notice from the Owner.
**Performed by:** IT Administrator (User Administrator + Intune Administrator via PIM).
**Target:** sign-in blocked within **15 minutes** of the request (on the last day,
or **immediately** for a termination).

## Steps

1. Activate **User Administrator** and **Intune Administrator** in PIM.
2. Dry run first, then for real:
   ```powershell
   ./scripts/graph/Invoke-Leaver.ps1 -UserPrincipalName <upn> -RetireDevices -WhatIf
   ./scripts/graph/Invoke-Leaver.ps1 -UserPrincipalName <upn> -RetireDevices
   ```
   The script, in order:
   1. Blocks sign-in
   2. Revokes refresh tokens and sessions
   3. Removes assigned group memberships (including SG-AWS-*)
   4. Removes direct licences (the group licence follows SG-All-Staff, which requires an enabled account)
   5. Retires Intune devices (removes company data only)
3. AWS: confirm IAM Identity Center shows the user disabled or removed after the
   next SCIM cycle (`scripts/aws/check-identity-center.sh`). If it's urgent, use
   **Provision on demand** in the Entra enterprise app.
4. Data handover: Owner decides who gets mailbox and OneDrive access. Convert
   the mailbox to shared if it must be kept.
5. After the retention period (lab: 30 days), delete the account.

## Why sessions are revoked as well as blocking sign-in

Blocking sign-in stops *new* sign-ins. An already-issued access token can stay
valid until it expires (typically up to about an hour). Revoking sessions
invalidates refresh tokens, and apps that support Continuous Access Evaluation
(Exchange Online, SharePoint Online, Teams) act on it in near real time.

## Verify (evidence T3.6)

- [ ] Log file from `out/leaver-*.log` copied into evidence (redacted)
- [ ] Sign-in as the user fails, with time recorded
- [ ] Open Outlook web session is kicked out (CAE), with time recorded
- [ ] AWS portal access gone after SCIM cycle, with time recorded
- [ ] Device shows Retire pending/complete in Intune
