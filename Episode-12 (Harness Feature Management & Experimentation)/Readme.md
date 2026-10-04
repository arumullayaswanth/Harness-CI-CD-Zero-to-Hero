# Episode 12: Harness Feature Management & Experimentation

### Feature Flags & Safe Releases

---

## Where This Fits (Roadmap 11–15)

| Episode | Topic | Main Focus |
| ------- | ------------------------------ | ----------------------------------- |
| 11      | Harness Code Repository        | Git, PRs, Code Reviews & Governance |
| **12**  | Feature Management             | Feature Flags & Safe Releases       |
| 13      | Cloud & AI Cost Management     | FinOps & Cost Optimization          |
| 14      | Service Reliability Management | Monitoring & Reliability            |
| 15      | Resilience Testing             | Chaos Engineering                   |

**Learning flow:** Code → Build → Deploy → **Release** → Cost → Reliability → Resilience

Episode 11 was about the code. Episode 12 is about **how you release features** — turning them on and off without redeploying.

---

## 🎯 Goal

Deploy an app once, then control a feature with a **Feature Flag** in Harness. Turn it on for developers, then 10% of users, then everyone — and turn it off instantly if something breaks. **No redeploy. No pipeline run.**

**Demo flow:**
```
Deploy app (flag OFF) → Enable for developers → Enable for 10% users → Enable for everyone → Disable instantly if there's a problem
```

---

## 🧩 What is Feature Management?

Normally, to release a feature you build a new image and redeploy. With feature flags, the feature is **already deployed but hidden behind a switch**. You flip the switch in Harness and the running app changes — instantly, with no deployment.

| Concept | What it means |
|---------|---------------|
| **Feature Flag** | A named on/off (or multi-value) switch your code checks at runtime |
| **Target** | Who is asking — a user, group, or segment (used for targeting) |
| **Environment-based flags** | Same flag can be ON in dev, OFF in prod |
| **Gradual rollout** | Turn on for 1% → 10% → 50% → 100% of users |
| **Targeting** | Turn on only for specific users/groups (e.g. internal testers) |
| **Kill switch** | Turn a broken feature OFF instantly — no rollback pipeline needed |
| **Experimentation / A/B** | Show variant A to some users, B to others, measure results |

---

## 🤔 Why Feature Flags Matter

| Without flags | With flags |
|---------------|-----------|
| Release = redeploy (risky, slow) | Release = flip a switch (instant) |
| Bad feature = rollback pipeline | Bad feature = turn flag OFF in seconds |
| All users get it at once | Gradual rollout, catch issues early |
| Deploy and release are the same event | Deploy and release are **separated** |

> **The big idea:** feature flags **separate deploy from release**. You can deploy code on Monday and release the feature on Friday to 10% of users — from the same running build.

---

## 📁 Project Structure

```
Episode-12 (Harness Feature Management & Experimentation)/
├── Readme.md                       ← This file
├── DEPLOY-STEPS.md                 ← Step-by-step demo guide
└── feature-flags-app/
    ├── app.js                      ← Node.js app; "new_checkout_banner" behind a flag
    ├── app.test.js                 ← Jest tests (flag OFF fallback)
    ├── package.json                ← includes @harnessio/ff-nodejs-server-sdk
    ├── Dockerfile                  ← multi-stage, non-root
    ├── .gitignore
    ├── .harness/
    │   └── feature-flags-pipeline.yaml  ← CI (build+ECR) + CD (NativeHelm deploy) pipeline
    └── helm/feature-flags-app/          ← Helm chart
        ├── Chart.yaml
        ├── values.yaml                  ← <+artifact.image> + <+secrets.getValue("harness_fme_sdk_key")>
        └── templates/
            ├── secret.yaml              ← ff-secrets (SDK key)
            ├── deployment.yaml          ← Deployment
            └── service.yaml             ← LoadBalancer Service
```

---

## 🔄 The Demo Flow

```
1. Deploy the app once — new_checkout_banner flag is OFF (nobody sees the banner)
2. In Harness → Feature Flags → turn ON for the "developers" target group only
3. Set a percentage rollout — 10% of users see it, 90% don't
4. Increase to 100% — everyone sees it
5. Something looks wrong? Flip the flag OFF → banner disappears instantly for everyone
```

At no point do you rebuild the image or run the pipeline again. The app just reads the flag at runtime.

---

## 🛠️ Technologies

| Category | Technology |
|----------|-----------|
| **Feature Flags** | Harness Feature Management & Experimentation (FME) |
| **SDK** | @splitsoftware/splitio (FME is Split-based) |
| **App** | Node.js 20 + Express |
| **Secrets** | Harness built-in Secret Manager (SDK key) |
| **CI/CD** | Harness CI (build+ECR) + CD (NativeHelm: HelmDeploy/HelmRollback) |
| **Packaging** | Helm chart |
| **Container** | Docker (multi-stage, non-root) |
| **Deploy** | Kubernetes (EKS) |

---

## 📋 How to Use

See **[DEPLOY-STEPS.md](./DEPLOY-STEPS.md)** for the full step-by-step demo.

---

## 💰 Cost

Harness Feature Flags has a free tier. The app runs on your existing EKS cluster. Destroy the deployment when done → minimal cost.

---

> 🎬 Previous: [Episode 11 - Harness Code Repository](../Episode-11%20(Harness%20Code%20Repository)/Readme.md)
> 🎬 Next: Episode 13 - Cloud & AI Cost Management
