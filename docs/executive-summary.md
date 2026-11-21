# Executive summary: Harbourline Advisory identity security

*For the Owner. One page, plain language.*

**Prepared by:** Manraj Singh Makin · **Date:** 21 November 2026

## What was built

Every Harbourline staff member now has **one company login** that is protected by
**multi-factor authentication** on their phone. Developers use that same login to reach
the company's **Amazon Web Services (AWS)** accounts. There are no separate AWS
passwords to manage or leak, and when someone is removed from the company system their
AWS access is switched off **within seconds**. Nobody on staff holds permanent
administrator rights: admin access is granted for a specific task and taken away
afterwards, and every step is recorded.

## Where we stand

| Area | Status | Evidence |
|------|--------|----------|
| Staff logins and MFA | ✅ In place: all staff must register MFA | Tested |
| Starting, moving and leaving staff | ✅ Scripted; a leaver is locked out on the next sign-in attempt | Tested (joiner, mover, leaver) |
| Administrator access | ✅ No standing admin rights for staff; emergency accounts protected and monitored | Tested, audit log |
| AWS access | ✅ Company login only; developers can build in Dev but cannot change Prod; every sign-in is logged | Tested (6 of 6) |
| Laptops (managed, encrypted, protected) | ❌ Not in place: needs a paid Microsoft licence | Designed, not deployed |
| Essential Eight (ASD) Maturity Level One | ⚠️ 0 met, 2 partly met, 6 not met | Self-assessment |

**Tests:** 16 passed; 19 could not be run without paid licences, and each one has a
documented reason and a compensating control.

## Current risk

1. **No device management (High).** We cannot yet require that laptops are patched,
   encrypted and protected before they reach company data.
2. **No backups of Microsoft 365 data (Medium).** Data lost or encrypted by ransomware
   could not be restored.
3. **Admin access relies on manual discipline (Medium).** Granting and removing
   admin rights works and is logged, but nothing removes them automatically if someone forgets.

## Top three recommendations

1. **Buy Microsoft 365 Business Premium for all staff** (or E3/E5 for the stronger
   controls). The device, Conditional Access and protection settings are already
   written and tested in design, so this mainly switches them on.
2. **Add a Microsoft 365 backup service** and test a restore every quarter.
3. **Turn on just-in-time admin approval (PIM)** and remove the two remaining
   build-time administrator accounts.

## Cost and effort

- **Running cost today:** effectively nil. AWS identity services are free; the
  logging storage costs cents a month, capped by a US$5 budget alert.
- **To close the gaps:** a Microsoft 365 licence per staff member plus a backup
  service (check current pricing), and roughly **2 to 4 hours a month** of admin
  time for reviews: weekly emergency-account sign-in check, quarterly access review.
