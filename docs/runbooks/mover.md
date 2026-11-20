# Runbook: Mover

**Trigger:** confirmed role change from the Owner.
**Performed by:** IT Administrator (User Administrator via PIM).
**Risk being controlled:** privilege creep, where someone keeps old access after moving.

## Steps

1. Record the old and new department and the effective date.
2. Activate **User Administrator** in PIM.
3. Change the department:
   ```powershell
   Update-MgUser -UserId <upn> -Department 'Advice' -JobTitle 'Financial Adviser'
   ```
   On P1, dynamic groups do the rest. **On Entra ID Free (EX-006)**, sync the groups:
   ```powershell
   ./scripts/graph/New-LabGroups.ps1 -Domain <tenant>.onmicrosoft.com -FreeTier
   ```
   Expect a `REMOVE ... from SG-Dept-<old>` and a `MEMBER ... -> SG-Dept-<new>` line.
4. Review **assigned** (non-dynamic) groups by hand; these do not change on their own:
   - Leaving Development? Remove from SG-AWS-Developers.
   - Anything else not needed for the new role.
5. Ask the user to sign out and back in (or revoke sessions) so new group claims apply.

## Verify (evidence T3.5)

- [ ] Removed from old SG-Dept-* group, added to new one
- [ ] Old department resources (Teams/SharePoint) no longer accessible
- [ ] Assigned groups reviewed; AWS access removed if no longer needed
- [ ] Record times: change made → membership updated
