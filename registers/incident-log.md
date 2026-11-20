# Incident log

Security events in the lab, how they were handled, and what changed afterwards.
Break-glass sign-ins are also recorded here (see `docs/runbooks/break-glass.md`).

| ID | Date | Severity | What happened | Response | Root cause | Prevention | Status |
|----|------|----------|---------------|----------|------------|------------|--------|
| INC-001 | 2026-11-20 | Medium | The one-time password of `bg-emergency-02` was captured in a screenshot while `New-BreakGlassAccounts.ps1` displayed it, and the screenshot was shared outside the password manager | Credential treated as exposed. Screenshot deleted and clipboard history cleared; password reset the same day and replaced with a new random 40+ character password stored only in the password manager | Screenshot taken while a secret was on screen | Rule added to the break-glass runbook: no screenshots while a credential is displayed; evidence is captured only after the screen is cleared | Open (rotation in progress) |
