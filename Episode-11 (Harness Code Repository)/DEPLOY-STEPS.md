# Episode 11: Harness Code Repository — Deployment Steps

```
Developer → Harness Code Repository → Pull Request → Code Review → CI Pipeline → Build → Merge
```

---

## Prerequisites (Already Done)

| What | Episode | Link |
|------|---------|------|
| Harness account + project (`HarnessCICDZerotoHero`) | 1 | [Episode 1 — Step 2](../Episode-01/hello-world-app/DEPLOY-STEPS.md#step-2-open-harness) |
| Docker Hub connector (`dockerhub`) | 2 | [Episode 2 — Step 5](../Episode-02/README.md#step-5-create-docker-hub-connector) |
| Secret: `docker-hub-password` | 2 | [Episode 2](../Episode-02/README.md) |
| Variable: `docker_username` | 2 | [Episode 2](../Episode-02/README.md) |

> Episode 11 creates **no AWS infrastructure**. Everything is inside Harness. Bill = $0.

---

## Step 1: Enable the Code Module

1. Login to Harness → https://app.harness.io
2. Left sidebar → click the module switcher → select **Code**
3. If prompted, click **Enable Code** for your project

> Harness Code is the built-in Git provider. No connector or PAT needed — the repo lives in Harness.

---

## Step 2: Create a Harness Code Repository

1. In the **Code** module → click **+ New Repository**
2. Choose one of:
   - **Create Repository** (empty) — name it `code-repo-app`
   - **Import Repository** — import from GitHub if you want to pull existing code
3. Fill in:
   - Name: `code-repo-app`
   - Description: `Episode 11 - Harness Code demo`
   - Default branch: `main`
   - Add a README: **Yes** (so `main` has an initial commit)
4. Click **Create Repository**

> You now have a native Git repo hosted in Harness with an HTTPS clone URL.

---

## Step 3: Push the Demo App into the Repo

Get the clone URL from the repo page (**Clone** button → HTTPS). Harness Code uses your **Harness API token** as the password.

```bash
# Clone the empty Harness Code repo
git clone https://git.harness.io/ACCOUNT_ID/PROJECT/code-repo-app.git
cd code-repo-app

# Copy the Episode 11 app files into it (from this repo)
# (copy everything inside "Episode-11 (Harness Code Repository)/code-repo-app/")

git add .
git commit -m "Add Node.js demo app + CI pipeline"
git push origin main
```

> When Git asks for a password, use a **Harness Personal Access Token** (Profile → My API Keys → + Token). Username is your Harness email.

---

## Step 4: Import the CI Pipeline from the Harness Code Repo

1. Left sidebar → **Pipelines** → **+ Create a Pipeline**
2. Select **Import from Git**
3. Fill in:
   - **Git Connector / Provider:** select **Harness Code Repository**
   - **Repository:** `code-repo-app`
   - **Branch:** `main`
   - **YAML Path:** `.harness/code-repo-pipeline.yaml`
4. Click **Import Pipeline**
5. Open the pipeline → **Codebase** settings → **"Where is your code?"** → select **Harness Code Repository** → pick `code-repo-app` → **Save**

> (Source: [Harness docs — Set default codebase](https://developer.harness.io/docs/code-repository/pipelines/codebase-from-harness-code))

> The pipeline has one CI stage: Install Dependencies → Run Unit Tests → Build Docker Image → Summary.

### Optional: Run the pipeline once manually (registers the CI status check)

Run it once so the check name shows up in Branch Rules (Step 6).

1. Click **Run** → the **Run Pipeline** dialog opens
2. **CI Codebase → Build Type:** `Git Branch`
3. **Branch Name:** type `main` (if the dropdown shows *"No matching results found"*, just type `main` manually — the dropdown is empty until the repo has commits)
4. Click **Run Pipeline** → wait for green ✅

---

## Step 5: Add a Pull Request Trigger

This makes the pipeline run automatically whenever a PR is opened. The trigger is an **"On New Webhook"** trigger with Payload Type **Harness** (Harness Code).

1. Open the pipeline → **Triggers** tab → **+ New Trigger**
2. Under **Webhook**, choose **Harness** (Harness Code Repository)

**Tab 1 — Configuration:**
   - **Name:** `on-pull-request`
   - **Payload Type:** `Harness`
   - **Repository:** `code-repo-app`
   - **Event:** `Pull Request`
   - **Actions:** check **Create**, **Reopen**, **Update** (these run CI when a PR is opened or gets new commits)
   - **Auto-abort Previous Execution:** ✅ check it (cancels an in-progress build when the PR gets a new commit — saves CI minutes)
   - Click **Continue**

**Tab 2 — Conditions:**
   - **Target Branch:** operator `Equals`, value `main`
   - Click **Continue**

**Tab 3 — Pipeline Input:**
   - Leave **Input Set Source** and **Pipeline Source** = `<+trigger.branch>`
   - Leave **Pipeline Stages** = `All Stages`
   - Make sure the trigger is **Enabled** (toggle top-left)
   - Click **Create Trigger**
> Reference YAML is in `code-repo-app/.harness/triggers.yaml`.

### Step 5b: Add a Push Trigger (build on merge to main)

This runs the pipeline automatically when a PR is merged (push to `main`).

1. **Triggers** tab → **+ New Trigger** → **Webhook** → **Harness**

**Configuration:**
   - **Name:** `on-push-main`
   - **Payload Type:** `Harness`
   - **Repository:** `code-repo-app`
   - **Event:** `Push`
   - Click **Continue**

**Conditions:**
   - **Target Branch:** `Equals` `main`
   - Click **Continue**

**Pipeline Input:**
   - **Build Type:** `Git Branch`
   - **Branch Name:** `main`
   - Enabled → **Create Trigger**

---

## Fully Automatic Flow (No Manual Runs)

Once both triggers + the branch rule are set up, everything runs on its own:

```
Open / update a PR
      ↓  (PR trigger fires automatically)
CI runs: install → test → build   →  posts ✅/❌ status check on the PR
      ↓
Branch Rule blocks Merge until: CI ✅  AND  1 approval ✅
      ↓
Merge to main
      ↓  (Push trigger fires automatically)
CI runs again → builds + pushes the final image
```

| Trigger | Fires on | Purpose |
|---------|----------|---------|
| `on-pull-request` | PR opened / reopened / updated | Validate the PR before merge |
| `on-push-main` | Merge / push to `main` | Build + push the final image |

> After this, you never click **Run** manually — the PR and merge events drive the pipeline.

---

## Step 6: Add a Branch Rule on `main` (Governance)

This is the governance core — protect `main` so nothing merges without review + green CI.

1. In the **Code** module → open `code-repo-app` → **Settings** → **Branch Rules** (or **Protection Rules**)
2. Click **+ New Branch Rule**
3. Fill in:
   - Name: `protect-main`
   - Target branch: `main` (pattern)
   - Enable: **Require pull request** (block direct pushes to main)
   - Enable: **Require a minimum number of approvals** → set to **1**
   - Enable: **Require status checks to pass** → select the CI pipeline check (`code-repo-pipeline`)
   - Optional: **Require comment resolution**, **Block force push**
4. Click **Save**

> Now `main` cannot be merged into unless: at least 1 approval AND the CI pipeline passed.

---

## Step 7: Demo — Open a Pull Request

1. Create a feature branch and make a small change:

```bash
git checkout -b feature/update-message
# edit code-repo-app/app.js — change the welcome message text
git add .
git commit -m "Update welcome message"
git push origin feature/update-message
```

2. In Harness Code → the repo shows **"Compare & Pull Request"** → click it
3. Fill in PR title/description → **Create Pull Request**

---

## Step 8: Watch the CI Gate + Review

1. Opening the PR fires the trigger → the **CI pipeline runs automatically**
2. On the PR page you'll see:
   - **Checks:** `code-repo-pipeline` → Running → ✅ Passed
   - **Reviewers:** add a reviewer (or approve yourself if allowed)
3. The **Merge** button stays **disabled** until:
   - ✅ CI check passed
   - ✅ at least 1 approval
4. Approve the PR → CI green → **Merge** button unlocks → click **Merge Pull Request**

```
PR opened
   ↓
CI pipeline runs (install → test → build)   ✅
   ↓
Reviewer approves                            ✅
   ↓
Merge button unlocks → Merge to main         ✅
```

---

## Step 9: (Optional) Build on Merge to main

If you added the **Push** trigger (Step 5 reference YAML), merging to `main` runs the pipeline again to build and push the image with the merge commit.

1. After merge → check **Pipelines → Executions**
2. You'll see a new run triggered by the push to `main`

---

## Step 10: Cleanup

Nothing to destroy — no AWS resources. To reset the demo:

1. Delete the PR trigger (Pipelines → Triggers)
2. (Optional) Delete the branch rule (Code → Settings → Branch Rules)
3. (Optional) Delete the repository (Code → repo → Settings → Delete Repository)

**Bill = $0** (no infrastructure was created).

---

## Troubleshooting

| Problem | Cause | Fix |
|---------|-------|-----|
| `git push` asks for password / 401 | Wrong credential | Use a Harness **API token** as the password, Harness email as username |
| PR trigger doesn't fire | Trigger disabled or wrong repo | Pipelines → Triggers → confirm enabled + repo = `code-repo-app` |
| Merge button never unlocks | Branch rule not satisfied | Ensure CI check passed AND required approvals met |
| CI check not listed in branch rule | Pipeline never ran once | Run the pipeline once so the status check name registers |
| Pipeline can't clone repo | Codebase connector wrong | Pipeline codebase must point to the Harness Code repo, not `account.Github` |
| Tests fail in CI | Missing deps | `npm install` runs before `npm test` — check the Install step logs |

---

## What Episode 11 Adds (vs Episodes 1-10)

| | Episodes 1-10 | Episode 11 |
|---|---|---|
| Git hosting | GitHub (external) | **Harness Code** (built-in) |
| Connector | `account.Github` (PAT) | Native Harness Code repo (no PAT connector) |
| PR + review | On GitHub | **Inside Harness** |
| Merge gate | GitHub branch protection | **Harness Branch Rules** (review + CI status check) |
| Where code lives | GitHub cloud | Harness platform |

---

## Key Takeaway

> Harness Code brings the source repository into the same platform as your pipelines and policies. A protected `main` branch that requires **both** a code review and a passing CI pipeline is exactly how enterprises prevent unreviewed or broken code from reaching production — now done end-to-end without leaving Harness.
