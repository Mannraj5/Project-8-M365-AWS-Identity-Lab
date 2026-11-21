# Video walkthrough script (about 5 minutes)

Recording tips:
- **Tool:** Clipchamp (built into Windows 11) records the screen and webcam and can **blur**
  regions. Xbox Game Bar (`Win + Alt + R`) also works.
- **Privacy:** most of the video uses the **GitHub repo and the redacted evidence screenshots**,
  which are already safe. For any live part, check nothing shows the tenant domain, account IDs,
  emails, IP addresses or passwords, or blur it in Clipchamp before exporting.
- Speak to the audience: a hiring manager for a cloud, identity or security role.
- Rehearse once; aim for natural rather than perfect.

---

## 0:00–0:30 Hook and scenario

**Show:** GitHub repo README, top of page.

> "Hi, I'm Manraj, a Bachelor of IT student specialising in cyber security at Deakin.
> This is Project 8: I built and tested the identity security for a fictional 8-person
> financial advisory firm, Harbourline Advisory, across Microsoft Entra ID and AWS,
> and documented it to the standard an auditor would expect."

## 0:30–1:15 The constraint and the design decision

**Show:** README → *Licensing: a deliberate constraint* table, then the exception register.

> "Every paid Microsoft trial needs a credit card and auto-renews. I decided the risk
> wasn't worth it, so the lab runs on Entra ID **Free**. Instead of skipping controls, every
> control that needs a licence (Conditional Access, PIM, Intune) is fully designed and
> scripted, and logged here as an exception with a compensating control and a review date.
> Knowing what you *can't* do, and managing that risk, is part of the job."

## 1:15–2:15 Identity foundation and least privilege

**Show:** `evidence/screenshots/T1.1-groups.png`, `T1.4-security-defaults.png`,
then `T3.1b-*` (role granted → user created → role removed → audit log).

> "Users and groups are created by PowerShell and Microsoft Graph scripts, with a
> safeguard that refuses to run against any tenant but the lab's. I added that after
> nearly signing in with my university account. MFA is enforced through Security Defaults.
> Staff hold no standing admin rights: here the IT admin is denied, then gets User
> Administrator for one task, and it's removed ten minutes later. The audit log
> shows every step."

## 2:15–3:00 Lifecycle: joiner, mover, leaver

**Show:** `evidence/T3.4-T3.6-lifecycle.md`, then `T3.6-leaver-signin-refused.png`.

> "A new starter joins Finance and gets the right groups automatically. When she moves to
> Advice, the same script adds the new access *and removes the old one*, so there's no
> privilege creep. When she leaves, one command blocks sign-in and revokes sessions,
> and her next sign-in attempt is refused."

## 3:00–4:15 The highlight: one identity, two clouds

**Show:** `T6-org-accounts.png` → `T6-identity-center-single-region.png` →
`T6.2-sso-access-portal-sam.png` → `T6.3-dev-developer-allowed.png` and
`T6.3-prod-readonly-denied.png` → `T6.4-4-aws-user-disabled.png` → `T6.5-cloudtrail-federate-event.png`.

> "On AWS I built an Organization with Dev and Prod accounts and connected IAM Identity
> Center to Entra: SAML for sign-in, SCIM to create users. I kept Identity Center in Sydney
> only, with an AWS-owned key, for data residency and cost.
> A developer signs in with his company account and **no AWS password**. He can create a
> bucket in Dev, but the same action is **denied in Prod**, and denied outside Sydney.
> Remove someone in Entra and their AWS identity is disabled within seconds. CloudTrail
> records exactly who assumed which role, in which account, and when.
> Finally, I found a legacy IAM user with a long-lived access key in the credential
> report and retired it. There are now zero IAM users."

## 4:15–4:45 Honest results

**Show:** `docs/essential-eight-assessment.md` summary, then `registers/incident-log.md`.

> "Results: 16 tests passed, and 19 blocked by licensing, each documented. On the
> Essential Eight, the identity strategies are partly met and the device strategies are
> not, because there was no device licence. I also logged real incidents, like a
> break-glass password that ended up in a screenshot, which I rotated the same day."

## 4:45–5:00 Close

**Show:** README *Results at a glance*.

> "Everything (scripts, policies, runbooks and evidence) is in this repo. Thanks for
> watching; I'd love to talk about how I'd take this into a production environment."
