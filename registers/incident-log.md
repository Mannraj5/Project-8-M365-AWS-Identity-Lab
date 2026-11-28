# Incident log

Security events in the lab, how they were handled, and what changed afterwards.
Break-glass sign-ins are also recorded here (see `docs/runbooks/break-glass.md`).

| ID | Date | Severity | What happened | Response | Root cause | Prevention | Status |
|----|------|----------|---------------|----------|------------|------------|--------|
| INC-001 | 2026-11-20 | Medium | The one-time password of `bg-emergency-02` was captured in a screenshot while `New-BreakGlassAccounts.ps1` displayed it, and the screenshot was shared outside the password manager | Credential treated as exposed. Screenshot deleted and clipboard history cleared; password reset the same day and replaced with a new random 40+ character password stored only in the password manager | Screenshot taken while a secret was on screen | Rule added to the break-glass runbook: no screenshots while a credential is displayed; evidence is captured only after the screen is cleared | Closed 2026-11-20: password reset and replaced; Authenticator and device-bound passkey registered |
| INC-002 | 2026-11-20 | Low | The password stored for `bg-emergency-01` did not match the account (recorded incorrectly at creation), so the emergency credential would not have worked when needed | Password reset the same day; new password generated **in** the password manager, saved first, then entered; sign-in tested | Password copied manually from the terminal and saved incorrectly | Generate and save credentials in the password manager before using them; break-glass sign-in is tested at setup and quarterly | Closed 2026-11-20 |
| INC-003 | 2026-11-28 | Low | The Project 9 SIEM rule for break-glass sign-ins flagged `bg-emergency-01`: two successful **non-interactive** sign-ins on 2026-11-27 (Microsoft Office and Bing apps on the owner's phone, MFA satisfied). The account had stayed signed in to those apps since its passkey was set up, and the apps kept refreshing tokens in the background | Confirmed as the owner's own device, not an attacker. All sign-in sessions revoked in Entra (Revoke sessions) and the account signed out of both apps on the phone the same day. Role and passkey kept | After the passkey setup, the account was left signed in to everyday apps on a personal device. Anyone with the unlocked phone could have used a Global Administrator session | Break-glass accounts are never left signed in: after setup and after each quarterly test, sign out of every app and run Revoke sessions. Sign-ins by these accounts now alert in the Project 9 SIEM | Closed 2026-11-28 |

## Break-glass sign-in reviews (EX-010 compensating control)

Weekly, and after any use: Entra admin center > Monitoring & health > Sign-in logs,
filter *User principal name contains bg-emergency*, last 7 days.

| Review | Date | Reviewer | Sign-ins found | Unexpected? | Notes |
|--------|------|----------|----------------|-------------|-------|
| REV-001 | 2026-11-20 | Owner | 7 (both accounts, setup day) | No | All during MFA/passkey setup. One Failure (bg-emergency-02, error 50133: session invalid after password change) explained by the INC-001 reset; same location and IP as the successful sign-ins |
| REV-002 | 2026-11-28 | Owner | 3 (`bg-emergency-01`, last 2 days) | Yes, 2 | Two successful non-interactive sign-ins on 2026-11-27 from the owner's phone apps, raised as INC-003 and closed (sessions revoked). One failed sign-in on 2026-11-28 (error 50126) was the planned Project 9 lab test of the break-glass alert, which fired as expected |
