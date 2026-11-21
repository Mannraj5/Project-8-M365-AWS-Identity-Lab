# Test evidence

One row per acceptance test from the build guide. A phase is done only when
every test in it is **Pass** and its evidence is saved under
`evidence/screenshots/` (redacted) or `out/` logs copied here.

**Status key:** Not run · Pass · Fail · Blocked (reason and exception ID in *Actual result*)

> **Licensing:** the tenant runs on Microsoft Entra ID Free (EX-004). Tests that need P1, P2,
> Intune or Defender are **Blocked** and point to their exception. Some Phase 1 and 3 tests are
> adjusted to their Free-tier equivalent; the original expectation is kept for a licensed rerun.

**Redaction checklist before saving a screenshot:** tenant ID, tenant domain,
email addresses, IP addresses, AWS account IDs, access key IDs, device serials.

## Summary

| Phase | Tests | Pass | Fail | Blocked | Not run |
|-------|------:|-----:|-----:|--------:|--------:|
| 0 Preparation | 3 | 3 | 0 | 0 | 0 |
| 1 Identity foundation | 4 | 3 | 0 | 1 | 0 |
| 2 Conditional Access | 7 | 0 | 0 | 7 | 0 |
| 3 Privileged access & lifecycle | 6 | 4 | 0 | 2 | 0 |
| 4 Intune & Autopilot | 5 | 0 | 0 | 5 | 0 |
| 5 Defender | 4 | 0 | 0 | 4 | 0 |
| 6 AWS workforce access | 6 | 3 | 0 | 0 | 3 |
| **Total** | **35** | **13** | **0** | **19** | **3** |

## Test register

| ID | Phase | Test | Expected result | Date | Actual result | Status | Evidence |
|----|-------|------|-----------------|------|---------------|--------|----------|
| T0.1 | 0 | GitHub repo exists with the Section 7 structure | Repo and folders present | 2026-10-25 | Private repo created with the Section 7 structure; lint CI green from run #2 (run #1 flagged SC2015, fixed in 5569cde) | Pass | GitHub Actions run #2 |
| T0.2 | 0 | Windows 11 Enterprise VM boots; clean snapshot taken | VM reaches desktop; snapshot listed | 2026-10-25 | HL-WIN11-01 (VirtualBox 7.2, EFI, Secure Boot, TPM 2.0, 4 vCPU, 6 GB) installed with Win11 Enterprise eval 26H2 and local account only; ISO ejected; snapshot `Clean` taken | Pass | `screenshots/T0.2-clean-snapshot.png` |
| T0.3 | 0 | `scripts/graph/Test-LabPrereqs.ps1 -Connect` | All rows PASS | 2026-11-20 | PowerShell 7.7.0, Graph SDK 2.41.2, AWS CLI 2.38.5 and Connect-MgGraph (setup.admin, lab tenant) all PASS. Sign-in uses browser auth (`Set-MgGraphOption -DisableLoginByWAM $true`) because the Windows broker could not use the browser-stored passkey | Pass | `screenshots/T0.3-prereqs.png`, `screenshots/T0.3-prereqs-connect.png` |
| T1.1 | 1 | `New-LabUsers.ps1` then `New-LabGroups.ps1 -FreeTier` | 8 users; each in SG-All-Staff and the right SG-Dept-* group; devs in SG-AWS-Developers | 2026-11-20 | 8 users created (New-LabUsers.ps1). New-LabGroups.ps1 -FreeTier created 8 groups. Independent check from the tenant: SG-All-Staff 8; Dept-Advice priya, tom; Dept-Finance jack, mei; Dept-Dev ella, sam; AWS-Developers ella, sam; AWS-ReadOnly alex; Admins-PIM 0; BreakGlass 0. Management/IT staff are in SG-All-Staff only, as designed | Pass | `screenshots/T1.1-groups.png` |
| T1.2 | 1 | Users licensed through SG-All-Staff | Each staff user shows the licence as "Inherited" | 2026-11-20 | EX-004: Entra ID Free has no licences to assign | Blocked | |
| T1.3 | 1 | Sign in as a break-glass account; find it in the sign-in log (EX-010: no automated alert on Free) | Sign-in appears in the sign-in log and is reviewed within the weekly window | 2026-11-20 | Sign-in log filtered on bg-emergency (last 24 h): both accounts visible, Success after MFA/passkey setup (Interrupted rows = registration). One Failure for bg-emergency-02 at 10:35:12Z investigated: error 50133, session invalid after password change, same location/IP as the successful sign-ins, so benign and caused by the INC-001 rotation. Recorded as review REV-001 | Pass | `screenshots/T1.3-breakglass-signins.png` |
| T1.4 | 1 | Security Defaults **on** (Free tier, EX-005); every user prompted to register MFA | Settings screenshot | 2026-11-20 | Security defaults: Enabled. Staff test (priya.nair, first sign-in with temporary password): forced password change, then MFA registration required before access; Microsoft Authenticator registered | Pass | `screenshots/T1.4-security-defaults.png`, `screenshots/T1.4-staff-mfa-registered.png` |
| T2.1 | 2 | CA001: staff user signs in from a new browser | MFA prompt; sign-in log shows CA001 "Success" | 2026-11-20 | EX-005: Conditional Access needs Entra ID P1 | Blocked | |
| T2.2 | 2 | CA002: legacy auth attempt (e.g. SMTP AUTH / basic auth client) | Sign-in log "Failure", CA002 applied | 2026-11-20 | EX-005: Conditional Access needs Entra ID P1 | Blocked | |
| T2.3 | 2 | CA003: alex.admin activates a role, then signs in with password + app MFA | Blocked until phishing-resistant method used | 2026-11-20 | EX-005: Conditional Access needs Entra ID P1 | Blocked | |
| T2.4 | 2 | CA004: staff user opens Outlook web from an unmanaged device | Blocked: device not compliant | 2026-11-20 | EX-005: Conditional Access needs Entra ID P1 | Blocked | |
| T2.5 | 2 | CA005: What If with sign-in risk = High | CA005 would apply: Block | 2026-11-20 | EX-005: Conditional Access needs Entra ID P1 | Blocked | |
| T2.6 | 2 | CA006: What If with country ≠ AU (or VPN exit outside AU) | Blocked by CA006 | 2026-11-20 | EX-005: Conditional Access needs Entra ID P1 | Blocked | |
| T2.7 | 2 | `Export-LabCAPolicies.ps1` | 6 JSON files in `config/conditional-access/exported/`, no tenant IDs | 2026-11-20 | EX-005: Conditional Access needs Entra ID P1 | Blocked | |
| T3.1 | 3 | alex.admin creates a user **before** PIM activation | Fails: insufficient privileges | 2026-11-20 | Signed in to the Entra admin center as alex.admin (no directory role): 'Create new user', Edit and Delete are disabled. Finding: 'Invite external user' is still allowed for non-admins (tenant default), and non-admins can browse the admin center. Logged as RB-002/RB-003. Part 2 (manual just-in-time, compensating for EX-008): User Administrator assigned to alex.admin, user created by alex, test user deleted, role removed after about 10 minutes; audit log shows Add member to role (1:06), Add user (1:10), Remove member from role (1:16), all Success | Pass | `screenshots/T3.1-no-role-cannot-create-user.png`, `screenshots/T3.1b-1-role-granted.png` to `T3.1b-5-audit-log.png` |
| T3.2 | 3 | alex.admin activates User/Global Admin via PIM, retries | Succeeds; activation needed MFA + justification (+ Owner approval for GA) | 2026-11-20 | EX-008: PIM needs Entra ID P2 | Blocked | |
| T3.3 | 3 | PIM audit log | Shows request, approval, activation and expiry | 2026-11-20 | EX-008: PIM needs Entra ID P2 | Blocked | |
| T3.4 | 3 | Joiner runbook: create test user in Finance | Lands in SG-Dept-Finance, licensed, MFA registration prompted | 2026-11-21 | Nina Patel created (Finance) and synced to SG-All-Staff and SG-Dept-Finance; MFA registration enforced by Security Defaults (T1.4); no licence on Free (EX-004) | Pass | `T3.4-T3.6-lifecycle.md` |
| T3.5 | 3 | Mover runbook: change Finance → Advice, then re-run `New-LabGroups.ps1 -FreeTier` | Leaves SG-Dept-Finance, joins SG-Dept-Advice; access changes | 2026-11-21 | Department Finance → Advice, re-sync: added to SG-Dept-Advice and removed from SG-Dept-Finance in the same run | Pass | `T3.4-T3.6-lifecycle.md` |
| T3.6 | 3 | Leaver runbook: `Invoke-Leaver.ps1` on test user | Sign-in fails within the documented target (≤ 15 min) | 2026-11-21 | Invoke-Leaver.ps1 at 13:46:54: sign-in blocked, sessions revoked, removed from SG-All-Staff and SG-Dept-Advice. Next sign-in attempt refused: 'Your account has been locked' (within the 15-minute target) | Pass | `T3.4-T3.6-lifecycle.md`, `screenshots/T3.6-leaver-signin-refused.png` |
| T4.1 | 4 | Autopilot: VM reset, user-driven enrolment as staff user | ESP completes; device Entra joined | 2026-11-20 | EX-009: Intune/Autopilot licence not available card-free | Blocked | |
| T4.2 | 4 | Compliance policy | Device reports Compliant | 2026-11-20 | EX-009: Intune/Autopilot licence not available card-free | Blocked | |
| T4.3 | 4 | Turn firewall off on the VM | Device goes Non-compliant; M365 blocked by CA004 | 2026-11-20 | EX-009: Intune/Autopilot licence not available card-free | Blocked | |
| T4.4 | 4 | Windows LAPS | Admin retrieves local admin password in Intune/Entra | 2026-11-20 | EX-009: Intune/Autopilot licence not available card-free | Blocked | |
| T4.5 | 4 | App Control for Business (enforce) | Unapproved executable blocked; event logged | 2026-11-20 | EX-009: Intune/Autopilot licence not available card-free | Blocked | |
| T5.1 | 5 | Defender onboarding via Intune | Device shows Onboarded in Defender portal | 2026-11-20 | EX-009: Defender for Endpoint licence not available card-free | Blocked | |
| T5.2 | 5 | Detection test script + EICAR download | Alerts raised; incident note written | 2026-11-20 | EX-009: Defender for Endpoint licence not available card-free | Blocked | |
| T5.3 | 5 | Web content filtering | Blocked category denied in browser | 2026-11-20 | EX-009: Defender for Endpoint licence not available card-free | Blocked | |
| T5.4 | 5 | ASR rules (block mode) | Test triggers an ASR block event | 2026-11-20 | EX-009: Defender for Endpoint licence not available card-free | Blocked | |
| T6.1 | 6 | `scripts/aws/check-account-baseline.sh` (before Phase 6 step 7) | Root MFA, no root keys, budget exists, org trail logging | 2026-10-25 | Early checks in console: root MFA = passkey, root access keys = 0, $5 monthly budget created, alert email verified. Org trail and script run wait for Phase 6 | Not run | `screenshots/T6.1-root-mfa.png` |
| T6.2 | 6 | Developer signs in through Entra (My Apps → AWS) | Lands in AWS access portal; Dev = Developer, Prod = ReadOnly | 2026-11-21 | sam.okafor signed in at myapps.microsoft.com with his Entra account (Security Defaults MFA), opened the AWS IAM Identity Center tile and landed in the AWS access portal with no AWS password (SAML). Portal shows harbourline-dev → Developer and harbourline-prod → ReadOnly | Pass | `screenshots/T6.2-sso-access-portal-sam.png` |
| T6.3 | 6 | Developer tries to create an S3 bucket in Prod | AccessDenied | 2026-11-21 | Same user (sam.okafor), same action (S3 CreateBucket, Sydney): harbourline-prod as ReadOnly → 'Failed to create bucket… s3:CreateBucket permission is required'; harbourline-dev as Developer → bucket created (then deleted) | Pass | `screenshots/T6.3-prod-readonly-denied.png`, `screenshots/T6.3-dev-developer-allowed.png` |
| T6.4 | 6 | Remove a developer's access in Entra (Free tier: unassign the user from the AWS app, EX-011) | After next SCIM cycle, no AWS access | 2026-11-21 | ella.ruiz unassigned from the AWS IAM Identity Center app in Entra; Provision on demand sent active=false straight away (no 40-minute wait); Identity Center shows Ella Disabled while sam and alex stay Enabled | Pass | `screenshots/T6.4-1-app-assignment-removed.png` to `T6.4-4-aws-user-disabled.png` |
| T6.5 | 6 | `scripts/aws/find-signin-events.sh` | CloudTrail shows the Identity Center sign-in | | | Not run | |
| T6.6 | 6 | Legacy IAM user retired (`retire-legacy-iam-user.sh`) | Credential report shows no IAM users | | | Not run | |

## Detailed records

Copy this block for each test that needs more than one line.

```text
ID:
Date / time (UTC):
Tester:
Preconditions:
Steps:
  1.
  2.
Expected:
Actual:
Status:
Evidence: evidence/screenshots/<ID>-<short-name>.png
Notes / follow-up:
```
