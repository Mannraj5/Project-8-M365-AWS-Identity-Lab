# Runbook: AWS lab teardown

**When:** the lab is no longer needed (after interviews or demos).
**Who:** management account root user (passkey).
**Time:** about 30 minutes, plus up to 90 days for AWS to finish closing member accounts.
**Goal:** no running resources and no ongoing cost.

> Take a final screenshot of anything you still want as evidence **before** you start.
> Everything below is permanent.

Work through the steps **in order**: the trail must stop before its bucket can be
emptied, and Identity Center must be removed before the organisation can be deleted.

## 1. CloudTrail (stops log storage costs)

1. Region **Asia Pacific (Sydney)** → **CloudTrail** → **Trails**.
2. Select `harbourline-org-trail` → **Delete** → confirm.

## 2. The log bucket

1. **S3** → find `aws-cloudtrail-logs-<account>-…`.
2. **Empty** → type `permanently delete` → **Empty**.
3. **Delete** → type the bucket name → **Delete bucket**.
4. Check **S3** shows no other lab buckets (the Dev test bucket was already deleted).

## 3. Microsoft Entra side

1. Entra admin center → **Enterprise apps** → **AWS IAM Identity Center** →
   **Provisioning** → set **Provisioning Status** to **Off** → **Save**.
2. Same app → **Properties** → **Delete** → confirm.

## 4. IAM Identity Center

1. **IAM Identity Center** → **Settings** → **Management** tab →
   **Delete IAM Identity Center instance** → follow the prompts.
   This removes the users, permission sets and assignments.

## 5. Member accounts (Dev and Prod)

1. **AWS Organizations** → **AWS accounts** → select `harbourline-dev` →
   **Actions** → **Close** → confirm. Repeat for `harbourline-prod`.
2. Closed accounts show **Suspended**. AWS removes them permanently after about
   90 days. They cost nothing while suspended.

## 6. Organization (optional)

Once both member accounts have **left or been closed**, you can delete the
organization: **AWS Organizations** → **Settings** → **Delete organization**. If AWS
says member accounts are still attached, wait until their closure completes.

## 7. Budget and final check

1. Keep the **$5 budget** until the next bill shows **US$0.00**, then delete it if you wish
   (**Billing and Cost Management** → **Budgets**).
2. **Billing and Cost Management** → **Bills**: check the month's charges.
3. **Optional:** close the management account itself (**Account** → **Close account**) if
   you won't use AWS again. Download any invoices first.

## 8. Record it

Add a line to `docs/as-built.md` (change log): *"YYYY-MM-DD: AWS lab torn down per
`docs/runbooks/aws-teardown.md`; final bill US$x.xx."* Commit and push.
