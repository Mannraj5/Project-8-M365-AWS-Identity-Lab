# Runbook: Device enrolment (Windows Autopilot)

**Profile:** user-driven, Microsoft Entra joined, with Enrollment Status Page (ESP).

## One-time: register the device

On the VM (as local admin, PowerShell):
```powershell
Install-Script -Name Get-WindowsAutopilotInfo -Force
Get-WindowsAutopilotInfo -OutputFile C:\HWID\autopilot.csv
```
Import the CSV in Intune: **Devices > Windows > Enrollment > Devices > Import**.
Wait until the device shows the assigned profile.

> The hardware hash file identifies the device. Do not commit it.

## Enrol

1. Reset the VM (Settings > System > Recovery > Reset this PC, *Remove everything*)
   or revert to the clean snapshot.
2. At OOBE, connect to the network; the Harbourline branding should appear.
3. Sign in as a staff user; complete MFA.
4. ESP installs required apps and policies; wait for it to finish.

## Verify (evidence T4.1–T4.2)

- [ ] Device in Intune: Entra joined, Autopilot profile shown, primary user correct
- [ ] Compliance state **Compliant** (may take up to 30 min; *Sync* to speed up)
- [ ] User can open Outlook web on the device (CA004 satisfied)
