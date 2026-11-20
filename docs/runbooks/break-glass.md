# Runbook: Break-glass (emergency access)

**Accounts:** `bg-emergency-01`, `bg-emergency-02` (cloud-only, `.onmicrosoft.com`,
permanent Global Administrator, members of SG-BreakGlass).

## When to use

Only when normal admin access is impossible, for example:
- A Conditional Access policy locks out every admin
- The MFA service or federation is down
- alex.admin and the Owner are both unavailable during a security incident

**Not** for routine admin work. Every use is an incident.

## Handling the credentials

- The password is shown once at creation. Store it in the password manager (or offline, split) **before** pressing Enter.
- **Never screenshot, paste or send a break-glass password.** Capture evidence only after the screen has cleared.
- If a password is ever exposed, treat it as compromised: reset it the same day and record it in `registers/incident-log.md` (see INC-001).

## Lab configuration (as built 2026-11-20)

| Account | Methods | Notes |
|---|---|---|
| bg-emergency-01 | Password (40+ chars, password manager), Microsoft Authenticator push, **device-bound passkey** in Authenticator | Synced Google passkey removed: break-glass credentials must not depend on a personal cloud account |
| bg-emergency-02 | Same | Password rotated after INC-001 |

**Lab simplification:** both passkeys are on one phone, which is a single point of failure.
In production each account would use its own FIDO2 hardware key, stored in separate safes.

## How to sign in

1. Get the password from offline storage (two-person rule if possible).
2. Use a private browser window on a trusted device.
3. Sign in at https://entra.microsoft.com with the FIDO2 key or passkey.
4. Fix only the problem you came to fix. Note every action and time.

## Afterwards (within 24 hours)

1. Sign out; confirm the alert fired and was received.
2. Rotate the password (new random 40 characters) and store it offline again.
3. Review the account's sign-in and audit logs and attach them to an incident note.
4. Record the use in the exception register / incident log.

## Monitoring (set up in Phase 1, evidence T1.3)

**On Entra ID Free (EX-010):** there is no automated alert. Every week, and after any use,
open **Entra admin center > Monitoring & health > Sign-in logs**, filter **User** contains
`bg-emergency`, and record the result (date, any sign-ins, explanation) in the incident log.
The options below apply once the tenant has P1 and an Azure subscription.

Sign-ins by these accounts must alert. Options, best first:

1. **Log Analytics alert rule.** Send Entra sign-in logs to a Log Analytics
   workspace (Entra ID > Diagnostic settings), then create a log alert:
   ```kusto
   SigninLogs
   | where UserPrincipalName startswith "bg-emergency-"
   | project TimeGenerated, UserPrincipalName, AppDisplayName, IPAddress, ResultType
   ```
   Frequency 5 min, threshold > 0, action group emails Owner and Admin.
   (Log Analytics ingestion may cost a little; check the free allowance.)
2. **Defender for Cloud Apps activity policy** filtered on the two accounts (included in E5).

## Known gotcha: SSPR registration prompt

Admin accounts fall under Microsoft's fixed **administrator SSPR policy**, which
does not accept FIDO2. A break-glass account can get stuck at a "register
Authenticator + phone" prompt. Do not register personal phone numbers on it;
instead turn SSPR off for administrators (Graph, as Global Admin):

```powershell
Update-MgPolicyAuthorizationPolicy -AllowedToUseSspr:$false
```

This applies to all admin roles and can take up to 60 minutes. Record it in the as-built.

## Quarterly check

- [ ] Both accounts can still sign in (test, then rotate)
- [ ] Still excluded from every CA policy (`Export-LabCAPolicies.ps1` and grep for SG-BreakGlass)
- [ ] Alert still fires
- [ ] SG-BreakGlass has exactly these two members
