# Remediation backlog

Prioritised fixes from Microsoft Secure Score, Essential Eight gaps, AWS
findings and your own testing. Priority: **P1** fix now · **P2** this quarter · **P3** when convenient.

| ID | Source | Finding | Priority | Effort | Fix | Owner | Status |
|----|--------|---------|----------|--------|-----|-------|--------|
| RB-001 | Essential Eight | Regular backups only Partly met (EX-002) | P2 | M | Evaluate Microsoft 365 Backup or a third-party M365 backup; run and document a restore test | Owner | Open |
| RB-002 | Own finding (T3.1) | Non-admin members can invite external guests (tenant default) | P1 | S | External Identities > External collaboration settings > Guest invite settings: *Only users assigned to specific admin roles can invite guest users* | Owner | **Fixed 2026-11-21** (`evidence/screenshots/RB-002-guest-invites-admins-only.png`) |
| RB-003 | Own finding (T3.1) | Non-admin users can browse the Entra admin center (read-only) | P2 | S | Entra ID > Users > User settings > *Restrict access to Microsoft Entra admin center*: Yes. Note: does not block Graph/PowerShell reads | Owner | **Fixed 2026-11-21**, setting applied (`RB-003-009-user-settings-hardened.png`); verified: alex.admin (no role) gets 403 *Insufficient privileges* (`RB-003-non-admin-blocked.png`) |
| RB-004 | Own finding (Phase 1) | Four permanent Global Administrators (setup account, personal external account, two break-glass) | P2 | S | After build: remove Global Administrator from setup.admin and the external account; keep only the two break-glass accounts permanent. Use temporary role assignment for admin tasks (EX-008) | Owner | Open |
| RB-006 | Own finding (tenant defaults) | Users can register applications and agent identity blueprints (consent-phishing and data-access risk) | P1 | S | User settings: *Users can register applications* = No; *Users can register agent identity blueprints* = No | Owner | **Fixed 2026-11-21** (`evidence/screenshots/RB-003-009-user-settings-hardened.png`) |
| RB-007 | Own finding (tenant defaults) | Non-admin users can create new tenants (shadow IT) | P2 | S | User settings: *Restrict non-admin users from creating tenants* = Yes | Owner | **Fixed 2026-11-21** (`evidence/screenshots/RB-003-009-user-settings-hardened.png`) |
| RB-008 | Own finding (tenant defaults) | Users can create security groups (group sprawl undermines the access design) | P2 | S | User settings: *Users can create security groups* = No | Owner | **Fixed 2026-11-21** (`evidence/screenshots/RB-003-009-user-settings-hardened.png`) |
| RB-009 | Own finding (tenant defaults) | Work accounts can be connected to LinkedIn (profile data sharing) | P3 | S | User settings: *LinkedIn account connections* = No | Owner | **Fixed 2026-11-21** (`evidence/screenshots/RB-003-009-user-settings-hardened.png`) |
| RB-010 | Own finding (AWS) | Management account uses the default IAM password policy (8 characters) | P3 | S | IAM > Account settings > Password policy: 14+ characters, all character types, prevent reuse. Defence in depth only: the design has no IAM users | Owner | Open |
| RB-005 | Secure Score | *Fill in after review* | | | | | |

## Secure Score snapshot

Record before and after so the improvement is measurable.

| Date | Score | Max | % | Notes |
|------|------:|----:|--:|-------|
| | | | | Baseline after Phase 2 |
| | | | | After Phase 5 |
