# Runbook: Lost or stolen device

**Trigger:** user reports a lost or stolen laptop.
**Target:** remote action sent within **1 hour** of the report.

## Steps

1. Record: user, device name, when and where it was lost, whether it was locked.
2. Activate **Intune Administrator** in PIM.
3. Revoke the user's sessions (tokens on the device stop working):
   ```powershell
   Revoke-MgUserSignInSession -UserId <upn>
   ```
4. In Intune > Devices > the device:
   - **Stolen, or holds sensitive data:** *Wipe*. BitLocker protects data at rest;
     the wipe removes it when the device next connects.
   - **Probably misplaced:** *Remote lock* first and decide later.
5. Reset the user's password if it may have been seen or saved on the device.
6. Optional: *BitLocker key rotation* after the device is recovered.
7. Report to the Owner. Assess under the Notifiable Data Breaches scheme if
   personal information may be exposed.

## Verify

- [ ] Action shows *Complete* or *Pending* in Intune, with timestamp
- [ ] Sessions revoked, with timestamp
- [ ] Incident note written
