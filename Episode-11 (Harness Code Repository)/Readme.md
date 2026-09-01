# Episode 11: Harness Code Repository

### Git, Pull Requests, Code Reviews & Governance — inside Harness

---

## Where This Fits (Next 5-Episode Roadmap)

| Episode | Topic | Main Focus |
| ------- | ------------------------------ | ----------------------------------- |
| **11**  | Harness Code Repository        | Git, PRs, Code Reviews & Governance |
| 12      | Feature Management             | Feature Flags & Safe Releases       |
| 13      | Cloud & AI Cost Management     | FinOps & Cost Optimization          |
| 14      | Service Reliability Management | Monitoring & Reliability            |
| 15      | Resilience Testing             | Failure Testing & Chaos Engineering |

**Learning flow:** Code → Build → Deploy → Release → Cost → Reliability → Resilience

- Episodes 1-10: how to **build and deliver** software with Harness.
- Episodes 11-15: how to **manage** software after delivery.

Episode 11 goes back to the very start of the flow — **the code itself** — and shows how Harness can host your Git repositories natively, so code, pipelines, and governance all live in one platform.

---

## 🎯 Goal

Host a Git repository **inside Harness** (Harness Code Repository), open a Pull Request, get it reviewed, and have a **CI pipeline automatically gate the merge**. No external Git provider needed.

**Demo flow:**
```
Developer → Harness Code Repository → Pull Request → Code Review → CI Pipeline → Build → Merge
```

---

## 🧩 What is Harness Code Repository?

Harness Code is a **built-in Git provider** inside the Harness platform. Instead of connecting Harness to GitHub/GitLab/Bitbucket, you can host the repo directly in Harness.

| Concept | What it means |
|---------|---------------|
| **Repository** | A Git repo hosted in Harness (clone, push, pull like any Git repo) |
| **Branches** | Same Git branches — `main`, feature branches, etc. |
| **Pull Request (PR)** | Propose merging a branch into `main`, with diff view |
| **Code Review** | Reviewers approve/request changes before merge |
| **Branch Rules** | Protect `main` — require approvals + require CI checks to pass |
| **Governance** | OPA/security rules applied to the repo |
| **CI/CD integration** | A Harness Code repo can directly trigger Harness pipelines |

---

## 🤔 Why use Harness Code instead of external Git?

| Reason | Benefit |
|--------|---------|
| **One platform** | Code + pipelines + policies + secrets in a single place |
| **No connector setup** | The repo is native — no GitHub PAT/OAuth connector to maintain |
| **Tight CI/CD hooks** | PR/push events wire straight into pipelines and branch rules |
| **Governance built-in** | Branch protection + OPA policies enforced by the same platform |
| **Security** | Code never leaves the Harness/your-cloud boundary |

> **Note:** External Git (GitHub) is still fully supported — Episodes 1-10 used it. Harness Code is an option, not a replacement. Many teams keep source in GitHub and use Harness Code for internal/config repos.

---

## 📁 Project Structure

```
Episode-11 (Harness Code Repository)/
├── Readme.md                          ← This file (concepts + roadmap)
├── DEPLOY-STEPS.md                    ← Step-by-step demo guide
└── code-repo-app/                     ← Tiny Node.js app (focus stays on the Code Repo feature)
    ├── app.js                         ← Express API (/ , /health, /version)
    ├── app.test.js                    ← Jest + supertest unit tests (the CI gate)
    ├── package.json                   ← npm scripts (test, start)
    ├── Dockerfile                     ← Multi-stage, non-root
    ├── .gitignore
    └── .harness/
        ├── code-repo-pipeline.yaml    ← CI pipeline (install → test → build)
        └── triggers.yaml              ← PR trigger + push trigger (reference)
```

---

## 🔄 The Governance Flow (What Episode 11 Proves)

```
1. Developer creates a feature branch in Harness Code
2. Pushes a change, opens a Pull Request into main
3. Branch Rule on main requires:
     - at least 1 approving review
     - the CI pipeline status check to PASS
4. Opening the PR fires the PR trigger → CI pipeline runs (install → test → build)
5. Reviewer approves the code
6. Only when BOTH (review + CI green) are satisfied → Merge button unlocks
7. Merge to main → push trigger runs → build + push image
```

This is the same "protected main branch" pattern real companies enforce — just hosted entirely inside Harness.

---

## 🛠️ Technologies

| Category | Technology |
|----------|-----------|
| **Git Hosting** | Harness Code Repository (built-in Git) |
| **CI** | Harness CI (Cloud runtime) |
| **App** | Node.js 20 + Express |
| **Testing** | Jest + supertest |
| **Container** | Docker (multi-stage, non-root) |
| **Governance** | Branch Rules (required reviews + required status checks) |

---

## 📋 How to Use

See **[DEPLOY-STEPS.md](./DEPLOY-STEPS.md)** for the complete step-by-step demo.

**Quick start:**
1. Create a Harness Code repository (or import the `code-repo-app` folder)
2. Import the CI pipeline from the repo
3. Add a PR trigger
4. Add a Branch Rule on `main` (require review + require CI check)
5. Open a PR → watch CI run → review → merge

---

## 💰 Cost

Harness Code Repository and Harness CI (Cloud) are included in the **free tier** for this demo. No AWS infrastructure is created in Episode 11. **Cost = $0.**

---

> 🎬 Previous: [Episode 10 - Complete Enterprise Project](../Episode-10/README.md)
> 🎬 Next: Episode 12 - Feature Management & Experimentation
