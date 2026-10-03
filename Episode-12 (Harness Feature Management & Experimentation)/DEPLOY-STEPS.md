# Episode 12: Harness Feature Management — Deployment Steps

## What We Are Doing

Deploy an app once, then control a feature with a **Feature Flag** — turn it on for developers, then a % of users, then everyone, and off instantly if needed. No redeploy.

```
Deploy (flag OFF) → Developers → 10% users → Everyone → Kill switch OFF
```

---

## Prerequisites (Already Done)

| What | Episode | Link |
|------|---------|------|
| Harness account + project | 1 | [Episode 1](../Episode-01/hello-world-app/DEPLOY-STEPS.md) |
| GitHub connector (`account.Github`) | 1 | [Episode 1 — Step 3](../Episode-01/hello-world-app/DEPLOY-STEPS.md#step-3-create-a-github-connector-first-time-only) |
| EKS cluster + K8s connector | 6 | [Episode 6](../Episode-06/README.md) |
| ECR + AWS OIDC connector | 3-4 | [Episode 3](../Episode-03/README.md) |

---

## Step 1: Enable Feature Flags Module

1. Login to Harness → https://app.harness.io
2. Module switcher (left) → select **Feature Flags**
3. If prompted, click **Enable Feature Flags** for your project

---

## Step 2: Create an Environment

1. In your project → **Feature Flags** → **Environments** → **Create an Environment**
2. Enter a **Name**: `production` (Harness auto-generates the identifier)
3. Select **Environment Type**: **Production** → click **Create**

> Flags are shared across environments but toggled independently — ON in one, OFF in another.

---

## Step 3: Create an SDK Key (Server type)

1. Open the `production` environment → **Settings** → **Create SDK Key**
2. **Name**: `ff-server-key`
3. **Key Type**: **Server** (our Node.js app is server-side)
4. Click **Create**
5. **Copy and store the Secret now** — Harness redacts it once you leave the page. You'll paste it into the Harness Secret Manager in Step 5.

> Server SDK key = backend apps. Client SDK key = browser/mobile. We use Server.

---

## Step 4: Create the Feature Flag

1. **Feature Flags** → **Flags** → **+ New Flag** → select **Boolean**
2. Fill in:
   - **Name**: `new_checkout_banner`
   - **Identifier**: `new_checkout_banner` (must exactly match the code in `app.js`)
   - **Flag Type**: Boolean (ON / OFF)
3. Set the **variation when the flag is ON** = true, **OFF** = false
4. In **Default rules**, set the flag **OFF** for `production` (nobody sees the banner until you decide)
5. Click **Save** / **Create**

> The identifier `new_checkout_banner` must exactly match what the app checks in `app.js`.

---

## Step 5: Store the SDK Key in the Harness Secret Manager

We use the **built-in Harness Secret Manager** (no AWS SM, no ESO needed).

1. Harness → **Project Settings → Secrets → + New Secret → Text**
2. Secret Manager: **Harness Built-in Secret Manager** (default)
3. Fill in:
   - Secret Name / ID: `harness_ff_sdk_key`
   - Value: the **Server SDK key** from Step 2
4. Click **Save**

> How it flows: the Helm chart's `values.yaml` reads it with `<+secrets.getValue("harness_ff_sdk_key")>` → Helm templates it into `templates/secret.yaml` (`ff-secrets`) → `HelmDeploy` applies it. Masked in logs, never hardcoded.

---

## Step 6: Create the Service (`feature_flags_app`)

1. Harness → **Deployments → Services → + New Service**
2. Fill in:
   - Name: `feature-flags-app` → confirm the **Id** shows `feature_flags_app`
   - Click **Save**
3. Open the service → **Configuration** tab → **Deployment Type: Kubernetes**, then enable **Helm Chart** (NativeHelm)
4. Under **Manifests** → **+ Add Manifest**:
   - Manifest Type: **Helm Chart** → **Continue**
   - Store: **Github** → connector `account.Github`
   - Manifest Name: `feature-flags-app`
   - Branch: `master`
   - **Chart Path:** `Episode-12 (Harness Feature Management & Experimentation)/feature-flags-app/helm/feature-flags-app`
   - Helm Version: **V3**
   - Click **Submit**
5. Under **Artifacts** → **+ Add Primary Artifact**:
   - Type: **ECR** → connector `account.aws_account`
   - Region: your region (e.g. `us-east-1`)
   - **Artifact Source Identifier:** `ecr_image` (must match the pipeline)
   - Image Path: `feature-flags-app`
   - Tag: `<+input>`
   - Click **Submit**
6. Click **Save** on the service.

> Service type is **Kubernetes with Helm Chart (NativeHelm)** — the pipeline uses `HelmDeploy`/`HelmRollback`, not `K8sRollingDeploy`.

> NativeHelm resolves `<+artifact.image>` and `<+secrets.getValue("harness_ff_sdk_key")>` in the chart's `values.yaml`, then Helm templates them into the deployment/secret.

---

## Step 7: Create the CD Environment (`production`)

> This is the **Deployment** environment (CD module), separate from the Feature Flags environment in Step 2 — same name, different module.

1. Harness → **Deployments → Environments → + New Environment**
2. Fill in:
   - Name: `production` → confirm the **Id** shows `production`
   - Environment Type: **Production**
   - Click **Save**

---

## Step 8: Create the Infrastructure (`k8sdelegate`)

1. Open the `production` environment → **Infrastructure Definitions** tab → **+ Infrastructure Definition**
2. Fill in:
   - Name: `k8sdelegate` → confirm the **Id** shows `k8sdelegate`
   - Deployment Type: **Kubernetes**
   - Connector: your Kubernetes connector (e.g. `k8sdelegate` from Episode 6)
   - **Namespace:** `feature-flags`
   - Click **Save**

> Reuse the same K8s connector and EKS cluster from Episodes 6-10. No new cluster needed.

---

## Step 9: Import the Pipeline

1. Harness → **Pipelines → + Create a Pipeline → Import from Git**
2. Repo: `Harness-CI-CD-Zero-to-Hero`, Branch: `master`
3. YAML Path: `Episode-12 (Harness Feature Management & Experimentation)/feature-flags-app/.harness/feature-flags-pipeline.yaml`
4. **Import**

The pipeline has two stages:
- **build-and-push** (CI): unit tests → Create ECR Repo → BuildAndPushECR
- **deploy-helm** (CD): HelmDeploy (renders secret + deployment + service from the chart) → Health Check

> The pipeline references `serviceRef: feature_flags_app`, `environmentRef: production`, `infrastructureDefinitions: k8sdelegate` — the exact IDs you created in Steps 6-8. If your IDs differ, update them in the pipeline YAML.

---

## Step 10: Run the Pipeline (Deploy Once)

1. **Run Pipeline** → branch `master`
2. Flow:
   ```
   Stage 1 (build-and-push): Unit Tests → Create ECR Repo → Push Image
   Stage 2 (deploy-helm): HelmDeploy (chart renders secret + deployment + service) → Health Check
   ```
3. After deploy: `kubectl get svc -n feature-flags` → open the LoadBalancer URL

The store page loads with the banner **hidden** — the flag is OFF.

---

## Step 11: Demo — Turn the Flag ON

1. Harness → Feature Flags → `new_checkout_banner`
2. Toggle it **ON** for `production`
3. Refresh the app in the browser → the green banner appears **instantly** — no redeploy

```
Flag OFF → refresh → no banner
Flag ON  → refresh → "🎉 NEW: Faster one-click checkout is here!"
```

---

## Step 12: Demo — Targeting (developers only)

1. In the flag → **Targeting** → add a target rule
2. Serve **ON** to a specific target (e.g. identifier `dev-user`)
3. Test:
   - `http://LB-URL/?user=dev-user` → banner ON
   - `http://LB-URL/?user=random` → banner OFF

> The app passes `?user=` as the flag target, so Harness decides per-user.

---

## Step 13: Demo — Percentage Rollout (10% → 100%)

1. In the flag → **Percentage Rollout**
2. Set 10% ON / 90% OFF → some users see it, most don't
3. Increase to 50%, then 100%
4. This is how you release gradually and catch problems before everyone is affected

---

## Step 14: Demo — Kill Switch

1. Pretend the feature has a bug
2. Toggle the flag **OFF**
3. Refresh → the banner disappears **instantly for everyone** — no rollback pipeline, no redeploy

> This is the safety net: a bad release is a 1-second flag flip, not a 15-minute rollback.

---

## Step 15: Cleanup

```bash
kubectl delete namespace feature-flags
```
Delete the flag and environment in Harness if you want a clean slate. No AWS infra to destroy beyond the app.

---

## Troubleshooting

| Problem | Cause | Fix |
|---------|-------|-----|
| Banner never appears | Flag identifier mismatch | Must be exactly `new_checkout_banner` in code + Harness |
| App shows flag OFF always | SDK key missing/wrong | Check the `harness_ff_sdk_key` secret in Harness + the `ff-secrets` K8s secret |
| SDK can't connect | Client vs Server key | Use a **Server** SDK key for the Node.js app |
| Changes not instant | Streaming disabled | SDK uses `enableStream: true` (already set in app.js) |
| Pod CrashLoop | Secret not mounted | Confirm `ff-secrets` exists in `feature-flags` namespace |

---

## What Episode 12 Adds (vs Episode 11)

| | Episode 11 | Episode 12 |
|---|---|---|
| Focus | Hosting & reviewing code | Releasing features safely |
| Release method | Merge + deploy | **Flip a flag — no deploy** |
| Rollback | Revert PR + redeploy | **Turn flag OFF instantly** |
| Rollout control | All at once | **Gradual % + targeting** |

---

## Key Takeaway

> Feature flags separate **deploy** from **release**. The code ships once; you decide who sees the feature and when — and you can turn it off in one second if it misbehaves. That's the safest way to release in production.
