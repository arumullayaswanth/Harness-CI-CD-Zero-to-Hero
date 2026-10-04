# Episode 12: Harness Feature Management & Experimentation (FME) — Deployment Steps

## What We Are Doing

Deploy an app once, then control a feature with an **FME feature flag** — turn it on for a user, then a % of users, then everyone, and off instantly if needed. No redeploy.

```
Deploy (treatment OFF) → one user ON → 10% ON → 100% ON → kill switch OFF
```

> **Note:** Your account uses **Feature Management & Experimentation (FME)** — the Split-based module (nav shows Rollout Board, Experiments, Segments, Metrics, FME Settings). FME uses the **Split SDK** (`@splitsoftware/splitio`) and "treatments" (`on`/`off`/`control`), not the old FF SDK.

---

## Prerequisites (Already Done)

| What | Episode | Link |
|------|---------|------|
| Harness account + project | 1 | [Episode 1](../Episode-01/hello-world-app/DEPLOY-STEPS.md) |
| GitHub connector (`account.Github`) | 1 | [Episode 1 — Step 3](../Episode-01/hello-world-app/DEPLOY-STEPS.md#step-3-create-a-github-connector-first-time-only) |
| EKS cluster + K8s connector | 6 | [Episode 6](../Episode-06/README.md) |
| ECR + AWS OIDC connector | 3-4 | [Episode 3](../Episode-03/README.md) |

---

## Step 1: Open the FME Module

1. Login to Harness → https://app.harness.io
2. Module switcher (top-left grid) → select **Feature Management & Experimentation**
3. Select your project (e.g. `Harness-CI-CD-Zero-to-Hero`)

---

## Step 2: Create an Environment

1. Left nav → **Environments** → **Create Environment** (or **+ New**)
2. Name: `production`
3. Type: **Production** → **Create**

> FME flags are evaluated per environment — a flag can be ON in one env, OFF in another.

---

## Step 3: Create a Server-Side SDK Key

1. Left nav → **FME Settings** → **SDK Keys** (API Keys)
2. Click **Create SDK Key** / **+ API Key**
3. Fill in:
   - Name: `fme-server-key`
   - Environment: `production`
   - Type: **Server-side**
4. Click **Create** → **copy the key now** (store it; you'll paste it into the Harness Secret Manager in Step 5)

> Server-side key = backend apps (our Node.js app). Client-side = browser/mobile.

---

## Step 4: Create the Feature Flag

1. Left nav → **Feature Flags** → **Create Feature Flag**
2. Fill in:
   - Name: `new_checkout_banner` (must exactly match the code in `app.js`)
   - Traffic type: `user`
   - Treatments: **on** and **off** (FME defaults to these two)
3. In **Default rule / targeting** for `production`, set the default treatment to **off** (nobody sees the banner yet)
4. Click **Save** / **Create**

> The flag name `new_checkout_banner` must match `client.getTreatment(user, "new_checkout_banner")` in the app.

---

## Step 5: Store the SDK Key in the Harness Secret Manager

Use the **built-in Harness Secret Manager** (no AWS SM, no ESO needed).

1. Harness → **Project Settings → Secrets → + New Secret → Text**
2. Secret Manager: **Harness Built-in Secret Manager** (default)
3. Secret Name / ID: `harness_fme_sdk_key`
4. Value: the **server-side SDK key** from Step 3 → **Save**

> Flow: the chart's `values.yaml` reads it via `<+secrets.getValue("harness_fme_sdk_key")>` → Helm templates it into `templates/secret.yaml` (`ff-secrets`) → `HelmDeploy` applies it → pod reads `HARNESS_FME_SDK_KEY`. Masked in logs, never hardcoded.

---

## Step 6: Create the Service (`feature_flags_app`)

1. Harness → **Deployments → Services → + New Service**
   - Name: `feature-flags-app` → confirm **Id** = `feature_flags_app` → **Save**
2. **Configuration** → **Deployment Type: Kubernetes**, enable **Helm Chart** (NativeHelm)
3. **Manifests → + Add Manifest → Helm Chart**:
   - Store: **Github** → `account.Github`
   - Manifest Name: `feature-flags-app`
   - Branch: `master`
   - **Chart Path:** `Episode-12 (Harness Feature Management & Experimentation)/feature-flags-app/helm/feature-flags-app`
   - Helm Version: **V3** → **Submit**
4. **Artifacts → + Add Primary Artifact → ECR**:
   - Connector `account.aws_account`, Region your region
   - **Artifact Source Id:** `ecr_image` (must match the pipeline)
   - Image Path: `feature-flags-app`, Tag: `<+input>` → **Submit**
5. **Save**

> NativeHelm resolves `<+artifact.image>` and `<+secrets.getValue("harness_fme_sdk_key")>` in the chart's `values.yaml`, then Helm templates them into the manifests.

---

## Step 7: Create the CD Environment (`production`)

> This is the **Deployment** (CD) environment, separate from the FME environment in Step 2 — same name, different module.

1. Harness → **Deployments → Environments → + New Environment**
   - Name: `production` → **Id** = `production` → Type: **Production** → **Save**

---

## Step 8: Create the Infrastructure (`k8sdelegate`)

1. Open the `production` environment → **Infrastructure Definitions** → **+ Infrastructure Definition**
2. Fill in:
   - Name: `k8sdelegate` → **Id** = `k8sdelegate`
   - Deployment Type: **Kubernetes**
   - Connector: your K8s connector (from Episode 6)
   - **Namespace:** `feature-flags` → **Save**

---

## Step 9: Import the Pipeline

1. Harness → **Pipelines → + Create a Pipeline → Import from Git**
2. Repo: `Harness-CI-CD-Zero-to-Hero`, Branch: `master`
3. YAML Path: `Episode-12 (Harness Feature Management & Experimentation)/feature-flags-app/.harness/feature-flags-pipeline.yaml`
4. **Import**

The pipeline has two stages:
- **build-and-push** (CI): unit tests → Create ECR Repo → BuildAndPushECR
- **deploy-helm** (CD): HelmDeploy (chart renders secret + deployment + service) → Health Check

> The pipeline references `serviceRef: feature_flags_app`, `environmentRef: production`, `infrastructureDefinitions: k8sdelegate` — the IDs from Steps 6-8. Update them in the YAML if yours differ.

---

## Step 10: Run the Pipeline (Deploy Once)

1. **Run Pipeline** → branch `master`
2. Flow:
   ```
   Stage 1 (build-and-push): Unit Tests → Create ECR Repo → Push Image
   Stage 2 (deploy-helm): HelmDeploy (secret + deployment + service) → Health Check
   ```
3. After deploy: `kubectl get svc -n feature-flags` → open the LoadBalancer URL

The store page loads with the banner **hidden** (treatment = off / control).

---

## Step 11: Demo — Turn the Flag ON

1. FME → **Feature Flags** → `new_checkout_banner` → `production`
2. Set the **default rule** to serve **on**
3. Refresh the app → the green banner appears **instantly** — no redeploy

```
treatment off → refresh → no banner
treatment on  → refresh → "🎉 NEW: Faster one-click checkout is here!"
```

---

## Step 12: Demo — Targeting (one user)

1. In the flag → **Targeting** → add an **individual target**: serve **on** to key `dev-user`
2. Test in the browser (the app passes `?user=` as the Split key):
   - `http://LB-URL/?user=dev-user` → banner ON
   - `http://LB-URL/?user=random` → banner OFF

---

## Step 13: Demo — Percentage Rollout (10% → 100%)

1. In the flag's default rule → set a **percentage split**: 10% `on` / 90% `off`
2. Different `?user=` keys get bucketed consistently — some see it, most don't
3. Increase to 50%, then 100%

> FME buckets by the key you pass to `getTreatment`, so the same user always gets the same treatment at a given percentage.

---

## Step 14: Demo — Kill Switch

1. Pretend the feature has a bug → set the flag's default rule back to **off** (or use **Kill**)
2. Refresh → the banner disappears **instantly for everyone** — no rollback pipeline, no redeploy

---

## Step 15: Cleanup

```bash
kubectl delete namespace feature-flags
```
Delete the flag/environment/SDK key in FME if you want a clean slate. No AWS infra beyond the app.

---

## Troubleshooting

| Problem | Cause | Fix |
|---------|-------|-----|
| Treatment always `control` | SDK not ready / key wrong | Check `harness_fme_sdk_key` secret + `ff-secrets` K8s secret; must be a **server-side** key |
| Banner never appears | Flag name mismatch | Must be exactly `new_checkout_banner` in code + FME |
| App can't reach FME | Client vs server key | Use a **server-side** SDK key for the Node.js app |
| Changes not instant | SDK refresh | Split SDK polls ~every few seconds; wait a moment and refresh |
| Pod CrashLoop | Secret not mounted | Confirm `ff-secrets` exists in the `feature-flags` namespace (HelmDeploy creates it) |

---

## What Episode 12 Adds (vs Episode 11)

| | Episode 11 | Episode 12 |
|---|---|---|
| Focus | Hosting & reviewing code | Releasing features safely |
| Product | Harness Code | **FME (Feature Management & Experimentation)** |
| Release method | Merge + deploy | **Change a treatment — no deploy** |
| Rollback | Revert PR + redeploy | **Set treatment off instantly** |
| Rollout control | All at once | **Targeting + % rollout + experiments** |

---

## Key Takeaway

> FME separates **deploy** from **release**. The code ships once; you decide who sees the feature and when via treatments — and you can turn it off in one second if it misbehaves. FME also adds experiments and metrics on top, so you can measure a feature's impact, not just toggle it.
