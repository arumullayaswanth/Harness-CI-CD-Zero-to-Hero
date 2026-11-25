# Episode 13: Harness Cloud & AI Cost Management (CCM) — Setup & Demo Steps

## What We Are Doing

Connect AWS + EKS to Harness CCM, see where the money goes, find waste, set budgets/alerts, and apply savings recommendations.

```
Connect AWS → Enable K8s cost → Perspectives → Budget + Anomaly alert → Recommendations
```

> **Free tier:** CCM is Free Forever under $250K/month cloud spend — your account qualifies.

---

## Prerequisites (Already Done)

| What | Episode | Link |
|------|---------|------|
| AWS account (admin to create CUR + IAM role) | — | your AWS console |
| EKS cluster + K8s Delegate | 6 | [Episode 6 — Step 3](../Episode-06/gocart/DEPLOY-STEPS.md#step-3-install-kubernetes-delegate) |

---

# PART A — Connect AWS to CCM (cost visibility)

## Step 1: Enable the CCM Module

1. Login to Harness → https://app.harness.io
2. Module switcher → select **Cloud Cost Management**
3. Left nav shows: **Cost Explorer, Cost Categories, BI Dashboards** (Reporting) · **AutoStopping, Recommendations, Commitments** (Optimization) · **Budgets, Asset Governance, Anomalies** (Governance) · **Account Settings** (connectors live here)

---

## Step 2: Create a Cost & Usage Report (CUR) in AWS

> ⏰ Do this one day before recording. AWS takes up to 24 hours to write the first report.

### 2.1 Open the Create Report page
1. Log in to the AWS Console.
2. Search for **Billing and Cost Management** and open it.
3. In the left menu, **click Legacy Pages** select **Cost & Usage Reports**.
4. Click **Create report**.

> A banner says this page is "pending deprecation". Ignore it. Do not click **Try new experience**.

### 2.2 Specify report details (screen 1 of 3)
1. **Report name:** `harness-ccm-cur`
2. ✅ Tick **Include resource IDs**.
3. ✅ Tick **Split cost allocation data**.
4. ✅ Tick **Refresh automatically**.
5. Click **Next**.

### 2.3 Create the S3 bucket (popup)
- First create one S3 Bucket
1. Under **Configure S3 Bucket**, click **Configure**.
2. Select **Create a bucket**.
3. **S3 bucket name:** `harness-ccm-cur-713939171080`
4. **Region:** `us-east-1`
5. Click **Next**.
6. ✅ Tick **I have confirmed that this policy is correct**.
7. Click **Save**.

### 2.4 Set delivery options (screen 2 of 3)
1. **S3 path prefix:** `ccm`
2. **Report data time granularity:** **Hourly**
3. **Report versioning:** **Overwrite existing report**
4. ⬜ **Report data integration:** leave all unticked.
5. **Compression type:** **GZIP**
6. Click **Next**.

### 2.5 Review and create (screen 3 of 3)
1. Check the summary.
2. Click **Create report**.

### 2.6 Save these values for Step 3

| Value | What you entered |
|-------|------------------|
| Report name | `harness-ccm-cur` |
| S3 bucket | `harness-ccm-cur-713939171080` |
| S3 path prefix | `ccm` |

---

## Step 3: Create the AWS Connector in CCM

1. CCM → **Account Settings → Cloud Integration (Connectors) → + New Connector → AWS**

**1. Overview**
- **Connector Name:** `aws-ccm-connector`
- **AWS account ID:** `713939171080`
- **GovCloud:** **No**
- Click **Continue**

**2. Cost and Usage Report**
- Select **CUR 1.0 (legacy)**
- **Report name:** `harness-ccm-cur`
- **S3 bucket name:** `harness-ccm-cur-713939171080`
- Click **Continue**

**3. Choose Requirements**
- ✅ **Cost Visibility** (required)
- ✅ **Resource Inventory Management**
- ⬜ Optimization by AutoStopping
- ⬜ Cloud Governance
- ⬜ Commitment Orchestration
- Click **Continue**

**4. Create Cross Account Role**
- Click **Launch Template on AWS console** (opens AWS CloudFormation)
- ✅ Tick the IAM acknowledgement → **Create stack**
- Wait for **CREATE_COMPLETE**
- On the stack page, click the Outputs tab.
- Copy the **Role ARN** from the **Outputs** tab
- Back in Harness, paste it in **Cross Account Role ARN**
- **External ID** is already filled in. Don't change it.
- Click **Save and Continue**

**5. Connection Test**
- Wait for **Success** → **Finish**

> **Error "CUR report validation failed / No CUR file found":**
> 1. Check the bucket name in the connector is `harness-ccm-cur-713939171080`.
> 2. Check S3 has the folder `ccm/harness-ccm-cur/`. If not, AWS has not delivered the first report yet. Wait up to 24 hours and test again.

---

# PART B — Kubernetes cost

## Step 4: Enable Kubernetes Cost Collection

1. CCM → **Account Settings → Cloud Integration (Connectors) → + New Connector → Kubernetes**
2. Select your existing **K8s Delegate** connector (`k8sdelegate`, from Episode 6)
3. Enable **Cost Visibility**
4. Harness deploys a lightweight **cost collector** to the cluster (via the delegate)

---

## Step 5: Deploy the Over-Provisioned Demo Workload

So we have something wasteful for CCM to flag.

```bash
kubectl apply -f sample-workload/k8s/cost-demo.yaml
kubectl get pods -n cost-demo
```

> This runs 3 nginx pods each requesting 1 CPU / 1Gi but using almost nothing — CCM will show it as idle and recommend rightsizing (after it collects a day of data).

---

# PART C — See cost, find waste, control it

## Step 6: Explore Cost (Cost Explorer)

1. CCM → **Cost Explorer**
2. See cost broken down by **service** (EC2, EKS, S3, RDS…), **region**, **account**
3. Group by the `team` label to see cost per team (cost allocation). Use **Cost Categories** to define reusable groupings (e.g. by team/project).

---

## Step 7: Find Idle & Unused Resources

1. CCM → **Cost Optimization → Recommendations**
2. Look for:
   - **Rightsizing** — e.g. the `over-provisioned-app` (asked for 1 CPU, uses ~0)
   - **Idle EC2 / EBS / unattached volumes**
3. Each recommendation shows the **potential monthly savings** and the suggested change

> This is the "find waste" moment — point at the recommendation and the dollar figure it saves.

---

## Step 8: Set a Budget

1. CCM → **Cost Governance → Budgets → + New Budget**
2. Scope: your AWS cost view / Cost Category (or the `cost-demo` namespace)
3. Set a monthly limit (e.g. `$50`)
4. Alerts: notify at **80%** and **100%** of budget → email/Slack

---

## Step 9: Cost Anomaly Detection

1. CCM → **Cost Governance → Anomalies**
2. Harness ML automatically watches for spend spikes
3. Show how a sudden cost jump would be flagged here (no setup needed — it's automatic once cost data flows)

---

## Step 10: Apply a Recommendation (Cost-Saving Action)

1. Open the **rightsizing** recommendation for `over-provisioned-app`
2. It suggests dropping requests to the actual usage (e.g. 50m CPU / 64Mi)
3. Apply it by editing the workload:
   ```bash
   kubectl set resources deployment over-provisioned-app -n cost-demo \
     --requests=cpu=50m,memory=64Mi --limits=cpu=100m,memory=128Mi
   ```
4. CCM recalculates — the waste is gone

---

## Step 11: Cleanup

```bash
kubectl delete namespace cost-demo
```
Optionally delete the CUR + S3 bucket in AWS and the CCM connectors in Harness. CCM itself costs nothing.

---

## Troubleshooting

| Problem | Cause | Fix |
|---------|-------|-----|
| No cost data in CCM | CUR not generated yet | AWS takes up to 24h for the first CUR — wait |
| Connector test fails | IAM role not created | Re-run the CloudFormation template Harness provides |
| No K8s cost | Delegate cost collector not running | Check the K8s connector is enabled for Cost Visibility |
| No recommendations | Not enough history | Recommendations need ~a day of usage data to appear |
| K8s cost shows $0 | Cluster has no CUR link | AWS CUR must include the EKS cost; wait for data |

---

## Key Takeaway

> You can't optimize what you can't see. CCM gives DevOps engineers the same cost visibility finance has — spend by service, team, and workload — plus automatic waste detection, budgets, anomaly alerts, and concrete savings recommendations. That's DevOps + FinOps: engineers fixing the bill directly.
