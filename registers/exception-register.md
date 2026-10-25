# Exception register

A control that is not met, or met differently from the standard, is recorded
here with its risk and the compensating control. Every entry has an owner and
a review date. Risk rating = likelihood × impact (Low / Medium / High).

| ID | Control not met | Reason | Risk | Compensating control | Owner | Raised | Review by | Status |
|----|-----------------|--------|------|----------------------|-------|--------|-----------|--------|
| EX-001 | Apple device management (Apple Business Manager + Intune ADE) | ABM requires a real organisation with a D-U-N-S number; not possible in a personal lab | Low (lab has no Apple devices) | Out of scope. Any macOS/iOS device would be blocked from M365 by CA004 because it cannot be marked compliant | Owner | 2026-10-25 | End of project | Open |
| EX-002 | Essential Eight: Regular backups (ML1) | Only OneDrive Known Folder Move is in scope; no tested, offline or immutable backup of M365 data, and no restore test | Medium | OneDrive version history and recycle bin; M365 retention defaults | Owner | 2026-10-25 | End of project | Open |
| EX-003 | Break-glass accounts excluded from all Conditional Access | By design, so a CA misconfiguration cannot lock out the tenant | Medium | Phishing-resistant MFA (FIDO2) on both accounts, 40-char passwords stored offline, sign-in alert, role-assignable exclusion group, quarterly review | Owner | 2026-10-25 | Quarterly | Accepted |
| EX-004 | *Example: CA004 compliant-device requirement does not cover mobile devices* | *Only one Windows VM enrolled* | | | | | | |

## How to add an entry

1. Give it the next ID.
2. Be specific in **Control not met**: name the policy or Essential Eight requirement.
3. Rate the risk honestly; an exception with a High rating must have a review date within 30 days.
4. **Status:** Open (accepted temporarily, fix planned) · Accepted (permanent by design) · Closed (fixed; link the remediation backlog item).
