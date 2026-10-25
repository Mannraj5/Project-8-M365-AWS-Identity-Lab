# Runbook: Joiner

**Trigger:** signed offer and start date from the Owner.
**Performed by:** IT Administrator (User Administrator role, activated through PIM).
**Target:** account ready before the start date; first sign-in completes MFA registration.

## Design: why this is short

Access follows the **department** attribute. Setting it correctly puts the user in
SG-All-Staff (licence, CA004) and their SG-Dept-* group automatically. Only AWS
access is granted by hand, because it is higher risk.

## Steps

1. Activate **User Administrator** in PIM (see `pim-activation.md`).
2. Add the person to `data/users.csv` (lab) or create them directly:
   ```powershell
   ./scripts/graph/New-LabUsers.ps1 -Domain <tenant>.onmicrosoft.com
   ```
   Check: Department is one of Management, IT, Advice, Finance, Development. A typo
   means **no licence and no department access**.
3. Wait for dynamic membership (usually minutes), then confirm:
   ```powershell
   Get-MgUserMemberOf -UserId <upn> | ForEach-Object { $_.AdditionalProperties.displayName }
   ```
   Expected: SG-All-Staff and the right SG-Dept-* group.
4. Developers only: add to **SG-AWS-Developers** after the Owner approves. SCIM creates
   their AWS identity on the next cycle.
5. Give the temporary password through a separate channel from the username
   (for example, username by email, password by phone).
6. On day one, the user signs in, changes the password and registers MFA
   (Microsoft Authenticator; passkey preferred).
7. Enrol their device through Autopilot (`device-enrolment.md`).

## Verify (evidence T3.4)

- [ ] Correct groups, licence shows "Inherited" from SG-All-Staff
- [ ] MFA method registered
- [ ] Device enrolled and Compliant
- [ ] (Dev) AWS access portal shows the expected accounts
