# Essential Eight self-assessment

**Target:** Maturity Level One (ML1) across all eight strategies.
**Reference:** [ASD Essential Eight Maturity Model](https://www.cyber.gov.au/business-government/asds-cyber-security-frameworks/essential-eight/essential-eight-maturity-model)
**Assessed by:** Manraj Singh Makin · **Date:** 2026-11-21 · **Scope:** the lab as built
(Entra ID Free tenant, AWS organisation; no managed endpoints or Microsoft 365 apps).

> **How to read this.** This is a self-assessment of a portfolio lab, not an ASD
> assessment. A strategy is rated **Met** only when the evidence exists in this repo.
> The Essential Eight is mostly about endpoints (application control, patching, macros,
> hardening). The lab is identity-focused and could not license device management
> without a payment card (EX-004, EX-009), so most endpoint strategies are **Not met**,
> recorded honestly rather than claimed. Check each rating against the current ASD
> model, as requirements are updated over time.

| # | Strategy | What the lab has | Evidence | Rating | Gap → action |
|---|----------|------------------|----------|--------|--------------|
| 1 | Application control | Design only: App Control for Business via Intune | - | **Not met** | No managed devices (EX-009). Deploy with Intune on a licensed tenant |
| 2 | Patch applications | Design only: M365 Apps update channel, Intune app updates | - | **Not met** | No managed devices or M365 Apps (EX-009) |
| 3 | Configure Microsoft Office macro settings | Design only: block macros from the internet | - | **Not met** | No M365 Apps or Intune (EX-009) |
| 4 | User application hardening | Design only: browser hardening, web filtering, ASR rules | - | **Not met** | No managed devices or Defender (EX-009) |
| 5 | Restrict administrative privileges | No standing admin roles for staff; least-privileged role granted per task and removed, with audit trail; non-admins blocked from the admin portal; tenant defaults hardened; AWS: no IAM users, least-privilege permission sets, Admin set unassigned, centralised root | T3.1, RB-002 to RB-009, T6.3, T6.6 | **Partly met** | Validation is manual (no PIM, EX-008); build account and personal account still Global Admin (RB-004); no separate privileged operating environment |
| 6 | Patch operating systems | Design only: Windows Update rings or Autopatch | - | **Not met** | No managed devices (EX-009) |
| 7 | Multi-factor authentication | Security Defaults: every user registers Authenticator; MFA for admins and risky sign-ins; legacy auth blocked; break-glass and AWS root on phishing-resistant passkeys; AWS access only through Entra SSO | T1.3, T1.4, T6.1, T6.2 | **Partly met** | Security Defaults does not force MFA on every sign-in for every user, and phishing-resistant MFA is not enforced for all admins (CA001/CA003 need P1, EX-005) |
| 8 | Regular backups | None | - | **Not met** | No Microsoft 365 data in the lab; for production, back up M365 and test a restore (RB-001) |

## Summary

| Met | Partly met | Not met |
|----:|-----------:|--------:|
| 0 | 2 | 6 |

**Overall ML1: not achieved.** The identity strategies (5 and 7) are partly met
with tested evidence. The six endpoint strategies depend on device management, which
the lab could not license.

## What it would take to reach ML1

1. **License the tenant** (Microsoft 365 Business Premium or E3/E5). Deploy the
   ready-made Conditional Access policies (CA001 to CA006) to complete strategy 7.
2. **Enrol devices** with Intune/Autopilot (the VM and runbooks are ready). Apply
   App Control, update rings, the macro policy and Defender ASR rules for
   strategies 1, 2, 3, 4 and 6.
3. **PIM** for approval-based, time-limited admin access, and remove the build
   accounts' standing Global Admin (strategy 5, RB-004).
4. **Microsoft 365 backup** with a tested restore (strategy 8, RB-001).
