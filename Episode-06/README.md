# Episode 6: Continuous Delivery to Kubernetes

## 🎯 Goal
Deploy your application to Kubernetes using Harness CD.
Like delivering a pizza from the kitchen (CI) to the customer's door (Production).

---

## 📚 Topics Covered

### 1. What is Continuous Delivery (CD)?

```
CI (Episodes 1-5):     Code → Test → Build → Docker Image → Push to ECR
CD (This episode):     Docker Image → Deploy to Server → Users access it

CI  = You made the pizza 🍕
CD  = You delivered it to the customer 🚗💨
```

### 2. Kubernetes Concepts

| Concept | What It Is | Analogy |
|---------|-----------|---------|
| Namespace | Logical isolation | Floor in a building |
| ConfigMap | Non-secret config | Instructions on the fridge |
| Secret | Passwords, keys | Safe in the bedroom |
| Deployment | Manages pods | Apartment with rooms |
| Service | Network access | Doorbell |
| Pod | Running container | Room where app lives |

### 3. Deployment Strategies

| Strategy | Downtime | Risk | Best For |
|----------|----------|------|----------|
| **Rolling** | None | Low | Most apps (default) |
| **Blue-Green** | None | Low | Critical apps |
| **Canary** | None | Lowest | High-traffic apps |
| **Recreate** | YES | High | Dev/test only |

### 4. Rollback

```
Deploy v2 → Health check FAILS → exit 1 → Rollback auto-triggers
  Docker:  Pull :stable tag → Start previous container
  K8s:     kubectl rollout undo → Previous revision restored
```

### 5. Authentication Pattern

```
Stage 1 (Harness Cloud):
  ├── Create ECR Repo     → Access keys (aws-cli on Harness Cloud needs them)
  └── BuildAndPushECR     → OIDC connector (no keys!) ✅

Stage 2 (EC2 via SSH / K8s Delegate):
  └── All steps           → EC2 IAM Role / K8s Delegate (no keys!) ✅
```

| Step | Auth Method | Why |
|------|-------------|-----|
| `Create ECR Repo` (Run step) | Access keys | Harness Cloud can't use OIDC for aws-cli env vars |
| `BuildAndPushECR` (native step) | OIDC connector | Harness native step supports OIDC directly |
| `Deploy Container` (ShellScript) | EC2 IAM Role | Runs on EC2 via SSH, IAM role provides credentials |
| `kubectl apply` (ShellScript) | K8s Delegate | Delegate is inside EKS, has cluster access |

### 6. onDelegate: true vs false (ShellScript steps)

| | `onDelegate: true` | `onDelegate: false` |
|---|---|---|
| **Where script runs** | Inside delegate container | On the target host (via SSH) |
| **Has docker/aws?** | No (delegate is bare Java container) | Yes (EC2 host has everything installed) |
| **Needs SSH credential?** | No | Yes (uses infrastructure SSH config) |
| **Use case** | K8s delegate (has kubectl) | EC2/VM deployments (Secure Shell type) |

**`onDelegate: false` flow (Healthcare — EC2):**
```
Harness Cloud
    ↓ sends task
Docker Delegate (on EC2)
    ↓ delegate doesn't run script itself
    ↓ instead, SSHs into target host (using SSH credential)
    ↓
EC2 Host (script runs here)
    → has docker ✅
    → has aws-cli ✅
    → docker run, docker stop, etc.
```

**`onDelegate: true` flow (GoCart — EKS):**
```
Harness Cloud
    ↓ sends task
K8s Delegate (inside EKS cluster)
    ↓ delegate runs script inside its own container
    ↓
Delegate Container (script runs here)
    → has kubectl ✅ (pre-installed in K8s delegate)
    → kubectl apply, kubectl rollout, etc.
```

**Rule:**
- Secure Shell (`Ssh`) deployment → `onDelegate: false` (run on EC2 via SSH)
- Kubernetes deployment → `onDelegate: true` (run inside K8s delegate, has kubectl)

---

## ✅ Episode 6 Checklist

- [ ] Understand CD (deliver app to users)
- [ ] Know Kubernetes basics (Namespace, Deployment, Service, ConfigMap, Secret)
- [ ] Installed Docker Delegate for CD (no --network host, no tags)
- [ ] Deployed Healthcare website to EC2 via Docker
- [ ] Know all 4 deployment strategies
- [ ] Installed Kubernetes Delegate on EKS (from Bastion)
- [ ] Deployed GoCart to EKS via kubectl
- [ ] Understand rollback (:stable tag for Docker, rollout undo for K8s)
- [ ] Tested rollback by breaking deployment.yaml
- [ ] Understand when rollback triggers vs when pipeline just stops

---

## 🚀 Deployment Steps

### Two Topics in This Episode

| Topic | App | Delegate | Deploy Method | Access |
|-------|-----|----------|---------------|--------|
| **Topic 1** | Healthcare Website (HTML/CSS) | Docker Delegate (CD level) on EC2 | `docker run` | `http://EC2-IP` |
| **Topic 2** | GoCart E-Commerce (Next.js) | Kubernetes Delegate on EKS | `kubectl apply` | `http://LoadBalancer-URL` |

### Docker Delegate for CD (Different from Episode 3!)

```
Episode 3 (CI):                        Episode 6 (CD):
─────────────                          ─────────────
--network host   ✅ (for Runner)       No --network host
Tags: linux-amd64                      No tags
Docker Runner (port 3000)              No Runner needed
Purpose: Build code in containers      Purpose: Deploy containers
```

### Prerequisites (already done)

| What | Where | Episode | Link |
|------|-------|---------|------|
| GitHub connector (`account.Github`) | Account Settings → Connectors | Episode 1 | [Episode 1 — Deploy Steps](../Episode-01/hello-world-app/DEPLOY-STEPS.md) |
| AWS OIDC connector (`account.aws_account`) | Account Settings → Connectors | Episode 3 | [Episode 3 — Connector Setup](../Episode-03/README.md#connector-3-aws--🆕-create-now) |
| Secret: `aws_access_key_id` | Project Settings → Secrets | Episode 3 | [Episode 3 — Terraform README](../Episode-03/terraform-project/README.md#step-2-get-aws-access-key--secret-key) |
| Secret: `aws_secret_access_key` | Project Settings → Secrets | Episode 3 | [Episode 3 — Terraform README](../Episode-03/terraform-project/README.md#step-3-add-secrets-in-harness) |
| Variable: `aws_account_id` | Project Settings → Variables | Episode 4 | [Episode 4 — Deployment Steps](../Episode-04/README.md#step-1-add-aws-account-id-variable) |
| Variable: `aws_region` | Project Settings → Variables | Episode 3 | [Episode 3 — Terraform README](../Episode-03/terraform-project/README.md#step-4-add-variables-in-harness) |

### New Setup for Episode 6

**In Harness CD module UI (create manually before running pipeline):**

| # | What to Create | Where | Details |
|---|---------------|-------|---------|
| 1 | Service: `healthcare-website` | CD → Services | Type: Custom |
| 2 | Service: `gocart` | CD → Services | Type: Kubernetes, Manifests from Git, Artifact from ECR |
| 3 | Environment: `development` | CD → Environments | Type: Pre-Production |
| 4 | Infrastructure: `ec2-docker` | Inside `development` | Type: Custom, Delegate: `cd-docker-delegate` |
| 5 | Infrastructure: `eks-cluster` | Inside `development` | Type: Kubernetes, Inherit from Delegate |

See [Health care/DEPLOY-STEPS.md](./Health%20care/DEPLOY-STEPS.md) and [gocart/DEPLOY-STEPS.md](./gocart/DEPLOY-STEPS.md) for step-by-step.

---

## Project Structure

```
Episode-06/
├── README.md                              ← This file (theory + concepts)
│
├── Health care/                           ← TOPIC 1: Docker Delegate CD on EC2
│   ├── index.html                         ← Static Healthcare website
│   ├── styles.css                         ← CSS styling
│   ├── assets/                            ← Images (doctors, projects)
│   ├── Dockerfile                         ← Nginx serves static files
│   ├── DEPLOY-STEPS.md                    ← Step-by-step guide
│   └── .harness/
│       └── pipeline-docker-cd.yaml        ← Pipeline: ECR → docker run → EC2-IP:80
│
└── gocart/                                ← TOPIC 2: Kubernetes Delegate CD on EKS
    ├── app/                               ← Next.js 15 pages (public, admin, store)
    ├── components/                        ← React components (Hero, Cart, Products)
    ├── lib/                               ← Redux store (cart, product, address)
    ├── prisma/schema.prisma               ← PostgreSQL database schema
    ├── assets/                            ← Product images
    ├── package.json                       ← Next.js + React + Redux + Prisma
    ├── next.config.mjs                    ← Standalone output for Docker
    ├── Dockerfile                         ← Multi-stage (deps → build → standalone)
    ├── DEPLOY-STEPS.md                    ← Step-by-step guide
    ├── k8s/                               ← Kubernetes manifests
    │   ├── namespace.yaml                 ← gocart namespace
    │   ├── configmap.yaml                 ← App config (NODE_ENV, PORT)
    │   ├── secret.yaml                    ← DB credentials (DATABASE_URL)
    │   ├── postgres.yaml                  ← PostgreSQL 16 (Docker image on K8s)
    │   ├── deployment.yaml                ← 2 replicas + Rolling + Health probes
    │   └── service.yaml                   ← LoadBalancer (port 80 → 3000)
    └── .harness/
        └── pipeline-k8s-cd.yaml           ← Pipeline: ECR → kubectl apply → LoadBalancer
```

---

## Pipeline Flow Visualization

### Topic 1: Docker Delegate → EC2

```
┌──────────────────────────────────────────────────────────┐
│  TOPIC 1: HEALTHCARE WEBSITE ON EC2                       │
│                                                           │
│  Stage 1: Build & Push to ECR (CI stage, Harness Cloud)  │
│  ┌──────────┐  ┌──────────────────┐                     │
│  │Create ECR│→ │Build+Push (OIDC) │                     │
│  └──────────┘  └──────────────────┘                     │
│                     ↓                                     │
│  Stage 2: Deploy to EC2 (CD Deployment stage)            │
│  ┌──────────┐  ┌───────────┐  ┌──────────┐             │
│  │docker run│→ │Health Chk │→ │Tag:stable│             │
│  │-p 5000   │  │/health    │  │(success) │             │
│  └──────────┘  └───────────┘  └──────────┘             │
│                     │                                     │
│           If fails → Rollback (auto):                    │
│           Stop → Pull :stable → Start → Verify          │
│                     ↓                                     │
│  Stage 3: Approval ⏸️  →  Stage 4: Cleanup              │
│                                                           │
│  Access: http://EC2-IP:5000                              │
└──────────────────────────────────────────────────────────┘
```

### Topic 2: Kubernetes Delegate → EKS

```
┌──────────────────────────────────────────────────────────┐
│  TOPIC 2: GOCART E-COMMERCE ON EKS                       │
│                                                           │
│  Stage 1: Build & Push to ECR (CI stage, Harness Cloud)  │
│  ┌──────────┐  ┌──────────────────┐                     │
│  │Create ECR│→ │Build+Push (OIDC) │                     │
│  └──────────┘  └──────────────────┘                     │
│                     ↓                                     │
│  Stage 2: Deploy to EKS (CD Deployment stage)            │
│  ┌────────────────┐  ┌──────────┐  ┌──────────┐        │
│  │K8sRollingDeploy│→ │Verify    │→ │Health Chk│        │
│  │(Harness native)│  │Pods + LB │  │HTTP 200  │        │
│  └────────────────┘  └──────────┘  └──────────┘        │
│                     │                                     │
│           If fails → Rollback (auto):                    │
│           K8sRollingRollback (Harness native)            │
│                     ↓                                     │
│  Stage 3: Approval ⏸️  →  Stage 4: Cleanup              │
│                                                           │
│  Access: http://LOADBALANCER-URL 🛒                      │
└──────────────────────────────────────────────────────────┘
```

---

## Comparison: Topic 1 vs Topic 2

| | Topic 1: Docker CD (EC2) | Topic 2: Kubernetes CD (EKS) |
|---|---|---|
| **App** | Healthcare Website (HTML/CSS) | GoCart E-Commerce (Next.js) |
| **Delegate** | Docker Delegate (no `--network host`, no tags, no Runner) | Kubernetes Delegate (installed from Bastion) |
| **Deploy** | `docker run` on EC2 | `kubectl apply` on EKS |
| **Database** | None (static site) | PostgreSQL (Docker image on K8s) |
| **Access** | `http://EC2-IP:80` | `http://LOADBALANCER-URL` |
| **Replicas** | 1 container | 2 pods |
| **Health Check** | HTTP 200 | readinessProbe + livenessProbe |
| **Rollback** | `docker stop new → docker start old` | `kubectl rollout undo` |
| **Best for** | Simple apps, dev/test | Production, scalable apps |

---

## 📝 Key Takeaways

1. **CD = Deliver your app to users** (CI builds it, CD deploys it)
2. **Docker Delegate for CD** ≠ Docker Delegate for CI (no --network host, no tags, no runner)
3. **EC2 IAM Role** = no access keys needed in delegate stages
4. **`:stable` tag** = only updated after health check passes → safe rollback
5. **`kubectl rollout undo`** = K8s automatic rollback (uses revision history)
6. **`exit 1`** in health check → triggers rollback section automatically
7. **Deploy order matters** in K8s: namespace → configmap → secret → postgres → deployment → service

---

## 🧪 How to Test Rollback

### Healthcare Website (Docker on EC2)

| What to Break | Stage 1 | Stage 2 | Rollback? |
|---------------|---------|---------|-----------|
| `requirements.txt` (add invalid package) | ❌ Build fails | Never runs | No |
| `Dockerfile` (bad RUN command) | ❌ Build fails | Never runs | No |
| **`app.py`** (add `erxtcfgvhbjkmle` between imports) | ✅ Passes (image builds) | ❌ Flask crashes → `/health` no response | **YES ✅** |

**Best test for Healthcare:**
1. Run pipeline → success → `:stable` tagged ✅
2. Add garbage text in `app.py` (like `erxtcfgvhbjkmle` on line 5)
3. Push → Run pipeline
4. Stage 1: Image builds fine ✅ (Python doesn't check syntax at build time)
5. Stage 2: Container starts → Flask crashes → `/health` no response → Health check FAILS → **Rollback triggers** → pulls `:stable` → old version back ✅

---

### GoCart (Kubernetes on EKS)

| What to Break | Stage 1 | Stage 2 | Rollback? |
|---------------|---------|---------|-----------|
| `package.json` (invalid JSON) | ❌ Build fails | Never runs | No |
| `Dockerfile` (bad command) | ❌ Build fails | Never runs | No |
| **`k8s/deployment.yaml`** (invalid YAML) | ✅ Build passes | ❌ kubectl fails | **YES ✅** |
| **App runtime crash** (bad code) | ✅ Build passes | ❌ Health check fails | **YES ✅** |

**Best test for GoCart:**
1. Run pipeline → success ✅
2. Add garbage to `k8s/deployment.yaml` (like `dfghjk: invalid`)
3. Push → Run pipeline
4. Stage 1: Image builds fine (code is correct) ✅
5. Stage 2: `kubectl apply` fails on bad YAML → **Rollback triggers** → `kubectl rollout undo` → previous version restored ✅

---

Harness OIDC connector (aws_account) → Used in Episode 6, 7, 10 for deploying to EKS and pushing to ECR.

> 🎬 Next Episode: [Episode 7 - Helm, Amazon EKS & Amazon ECS Deployment](../Episode-07/README.md)
