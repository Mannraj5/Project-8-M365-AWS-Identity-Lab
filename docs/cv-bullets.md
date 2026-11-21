# CV and LinkedIn bullets

Numbers come from `evidence/test-results.md`. Each claim has evidence in this repo.

## CV (choose 3 or 4)

- Built a Microsoft Entra ID and AWS identity lab for a fictional regulated firm,
  federating **AWS IAM Identity Center with Entra ID (SAML 2.0 + SCIM)** across a
  3-account AWS Organization, with no IAM users and no long-lived human credentials.
- Designed and tested **least-privilege access**: scoped permission sets (Sydney-only
  Developer role, ViewOnly Prod, unassigned Admin) proven by allow/deny tests, plus
  just-in-time admin role grants with a full audit trail.
- Automated the **joiner, mover and leaver** lifecycle in PowerShell (Microsoft Graph);
  verified a leaver is locked out on the next sign-in and their AWS identity disabled
  within seconds via SCIM.
- Hardened the tenant by identifying and fixing **6 risky Entra ID defaults**; set up
  break-glass accounts on device-bound passkeys and logged and closed 2 security incidents.
- Documented the environment to audit standard: as-built, runbooks, **16 passing
  acceptance tests**, exception register, remediation backlog and an
  **ASD Essential Eight** self-assessment.

## Interview talking points

- Why the lab runs on Entra ID Free (card-free risk decision) and how every blocked
  control was handled: exception, compensating control, ready-to-deploy design.
- Why Identity Center was single-Region with an AWS owned key (data residency and cost).
- Why `ViewOnlyAccess` rather than `ReadOnlyAccess` for Prod.
- A safeguard added after nearly signing in with the wrong (university) account:
  scripts now refuse to run against any tenant except the lab's.
- INC-001: a break-glass password was exposed in a screenshot, then rotated the same
  day and a process rule was added.
