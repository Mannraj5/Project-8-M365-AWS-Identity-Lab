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

## On Entra ID Free (no PIM, EX-008): manual just-in-time

1. alex.admin asks for the **least-privileged** role for the task (for example *User Administrator*, not Global Administrator), giving the ticket or reason.
2. A Global Administrator assigns it: **Roles & admins > <role> > + Add assignments**.
3. alex signs out and in again, does the task, and tells the admin when finished.
4. The admin removes it straight away: **Roles & admins > <role>**, tick the user, **Remove assignments**.
5. Check **Audit logs**: *Add member to role* and *Remove member from role* bracket the task. Record the ticket and times.

Difference from PIM: nothing removes the role automatically if step 4 is forgotten, so the quarterly role review must check for leftover assignments.

## Steps (with PIM, Entra ID P2)

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
