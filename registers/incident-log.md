# Incident log

Security events in the lab, how they were handled, and what changed afterwards.
Break-glass sign-ins are also recorded here (see `docs/runbooks/break-glass.md`).

| ID | Date | Severity | What happened | Response | Root cause | Prevention | Status |
|----|------|----------|---------------|----------|------------|------------|--------|
| INC-001 | 2026-11-20 | Medium | The one-time password of `bg-emergency-02` was captured in a screenshot while `New-BreakGlassAccounts.ps1` displayed it, and the screenshot was shared outside the password manager | Credential treated as exposed. Screenshot deleted and clipboard history cleared; password reset the same day and replaced with a new random 40+ character password stored only in the password manager | Screenshot taken while a secret was on screen | Rule added to the break-glass runbook: no screenshots while a credential is displayed; evidence is captured only after the screen is cleared | Closed 2026-11-20: password reset and replaced; Authenticator and device-bound passkey registered |
| INC-002 | 2026-11-20 | Low | The password stored for `bg-emergency-01` did not match the account (recorded incorrectly at creation), so the emergency credential would not have worked when needed | Password reset the same day; new password generated **in** the password manager, saved first, then entered; sign-in tested | Password copied manually from the terminal and saved incorrectly | Generate and save credentials in the password manager before using them; break-glass sign-in is tested at setup and quarterly | Closed 2026-11-20 |

## Break-glass sign-in reviews (EX-010 compensating control)

Weekly, and after any use: Entra admin center > Monitoring & health > Sign-in logs,
filter *User principal name contains bg-emergency*, last 7 days.

| Review | Date | Reviewer | Sign-ins found | Unexpected? | Notes |
|--------|------|----------|----------------|-------------|-------|
| REV-001 | 2026-11-20 | Owner | 7 (both accounts, setup day) | No | All during MFA/passkey setup. One Failure (bg-emergency-02, error 50133: session invalid after password change) explained by the INC-001 reset; same location and IP as the successful sign-ins |
