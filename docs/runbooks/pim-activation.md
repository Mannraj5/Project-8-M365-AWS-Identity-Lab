# Runbook: PIM role activation

**Who:** alex.admin (eligible through SG-Admins-PIM). Approver for Global Administrator: olivia.owner.

## Role settings (configured in Phase 3)

| Role | Max activation | MFA | Justification | Approval |
|------|----------------|-----|---------------|----------|
| Global Administrator | 4 h | Required | Required | Owner |
| Intune Administrator | 4 h | Required | Required | No |
| Security Administrator | 4 h | Required | Required | No |
| User Administrator | 4 h | Required | Required | No |

Admin roles also fall under **CA003**, so activation needs a phishing-resistant
method (FIDO2 key or passkey) to sign in to admin portals.

## Steps

1. Entra admin center > **Identity Governance > Privileged Identity Management > My roles**.
2. Choose **Eligible assignments**, then **Activate** on the least-privileged role that does the job.
3. Duration: only what you need (≤ 4 h). Justification: ticket number and the task.
4. Global Administrator only: wait for Owner approval (Owner gets an email; approves in PIM > Approve requests).
5. Sign out and back in, or refresh the portal, so the new role is in your token.
6. When done, **Deactivate** rather than waiting for expiry.

## Verify (evidence T3.1–T3.3)

- [ ] Task fails before activation (screenshot of the error)
- [ ] Task succeeds after activation
- [ ] PIM audit log shows request, approval (GA), activation, and deactivation or expiry
