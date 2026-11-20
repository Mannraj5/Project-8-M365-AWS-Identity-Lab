# Exception register

A control that is not met, or met differently from the standard, is recorded
here with its risk and the compensating control. Every entry has an owner and
a review date. Risk rating = likelihood × impact (Low / Medium / High).

| ID | Control not met | Reason | Risk | Compensating control | Owner | Raised | Review by | Status |
|----|-----------------|--------|------|----------------------|-------|--------|-----------|--------|
| EX-001 | Apple device management (Apple Business Manager + Intune ADE) | ABM requires a real organisation with a D-U-N-S number; not possible in a personal lab | Low (lab has no Apple devices) | Out of scope. Any macOS/iOS device would be blocked from M365 by CA004 because it cannot be marked compliant | Owner | 2026-10-25 | End of project | Open |
| EX-002 | Essential Eight: Regular backups (ML1) | Only OneDrive Known Folder Move is in scope; no tested, offline or immutable backup of M365 data, and no restore test | Medium | OneDrive version history and recycle bin; M365 retention defaults | Owner | 2026-10-25 | End of project | Open |
| EX-003 | Break-glass accounts excluded from all Conditional Access | By design, so a CA misconfiguration cannot lock out the tenant | Medium | Phishing-resistant MFA (FIDO2/passkey) on both accounts, 40-char passwords stored offline, sign-in review, quarterly test | Owner | 2026-10-25 | Quarterly | Accepted |
| EX-004 | **Licensing: tenant runs on Microsoft Entra ID Free** | Every paid trial (M365 E3/E5, Entra ID P1/P2, Intune, Defender) needs a payment card. The lab is deliberately card-free to remove any risk of an unintended charge. Root cause of EX-005 to EX-011 | Medium | Full P1/P2 design kept in the repo (CA JSON, scripts, runbooks) and ready to deploy on a licensed tenant | Owner | 2026-11-20 | If a card-free licence becomes available | Accepted |
| EX-005 | Conditional Access CA001–CA006 not deployed | Conditional Access needs Entra ID P1 (CA005 needs P2) – see EX-004 | High | **Security Defaults ON**: MFA registration and MFA for admins and risky sign-ins, legacy authentication blocked. Policies kept as tested JSON in `config/conditional-access/` | Owner | 2026-11-20 | On licence | Accepted |
| EX-006 | Dynamic groups not available | Dynamic membership needs P1 | Low | `New-LabGroups.ps1 -FreeTier` keeps department groups in sync from the department attribute; run after every joiner, mover or leaver (manual trigger instead of automatic) | Owner | 2026-11-20 | On licence | Accepted |
| EX-007 | SG-BreakGlass / SG-Admins-PIM are not role-assignable | Role-assignable groups need P1 | Medium | Only Global Administrators exist in the tenant, so group membership is still admin-only in practice; membership checked in the quarterly review | Owner | 2026-11-20 | On licence | Accepted |
| EX-008 | No PIM, access reviews or risk-based Conditional Access | Need Entra ID P2 | High | No standing admin roles for staff (alex.admin gets a role only for a task and it is removed afterwards, logged in the audit log); quarterly manual role review | Owner | 2026-11-20 | On licence | Accepted |
| EX-009 | Intune, Autopilot and Defender for Endpoint (Phases 4–5) not deployed | Need Intune and Defender licences (card-required trials) | High | Windows 11 VM built and snapshotted (T0.2) with TPM 2.0, Secure Boot and an Autopilot-ready serial; runbooks written. Essential Eight device controls rated Not met | Owner | 2026-11-20 | On licence | Accepted |
| EX-010 | No automated alert on break-glass sign-in | Exporting sign-in logs to Log Analytics needs P1 and an Azure subscription in this tenant | Medium | Manual sign-in log review of bg-emergency-* accounts weekly and after any use (break-glass runbook) | Owner | 2026-11-20 | Weekly | Accepted |
| EX-011 | AWS app access assigned per user, not per group | Assigning groups to enterprise apps needs P1 | Low | Users assigned to the AWS IAM Identity Center app individually; joiner/leaver runbooks include the app assignment step | Owner | 2026-11-20 | On licence | Accepted |

## How to add an entry

1. Give it the next ID.
2. Be specific in **Control not met**: name the policy or Essential Eight requirement.
3. Rate the risk honestly; an exception with a High rating must have a review date within 30 days.
4. **Status:** Open (accepted temporarily, fix planned) · Accepted (permanent by design) · Closed (fixed; link the remediation backlog item).
