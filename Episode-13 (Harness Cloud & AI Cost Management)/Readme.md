# Episode 13: Harness Cloud & AI Cost Management (CCM)

### DevOps + FinOps — How to Control Your AWS Bill

---

## Where This Fits (Roadmap 11–15)

| Episode | Topic | Main Focus |
| ------- | ------------------------------ | ----------------------------------- |
| 11      | Harness Code Repository        | Git, PRs, Code Reviews & Governance |
| 12      | Feature Management             | Feature Flags & Safe Releases       |
| **13**  | Cloud & AI Cost Management     | FinOps & Cost Optimization          |
| 14      | Service Reliability Management | Monitoring & Reliability            |
| 15      | Resilience Testing             | Chaos Engineering                   |

**Learning flow:** Code → Build → Deploy → Release → **Cost** → Reliability → Resilience

Episodes 11-12 shipped software. Episode 13 answers the question every DevOps engineer eventually gets asked: **"why is our AWS bill so high, and how do we cut it?"**

---

## 🎯 Goal

Connect your AWS account (and your EKS cluster) to **Harness Cloud Cost Management (CCM)**, see exactly where the money goes, find waste (idle/unused resources), set budgets and anomaly alerts, and apply cost-saving recommendations.

**Demo flow:**
```
AWS account → Harness CCM → See cost breakdown → Find idle/unused resources →
Analyze Kubernetes cost → Set budget + anomaly alert → Apply recommendations
```

---

## 🧩 What is Cloud Cost Management (CCM)?

CCM is Harness's **FinOps** module. It ingests your AWS billing data (and K8s usage) and turns it into clear dashboards, waste reports, budgets, and automated recommendations.

| Concept | What it means |
|---------|---------------|
| **Cost visibility** | See spend by service, account, region, tag — not a mystery bill |
| **Perspectives** | Custom views that slice cost by team, project, environment |
| **Cost allocation** | Attribute spend to the right team/app via tags & labels |
| **Kubernetes cost** | Break an EKS bill down to namespace / workload / pod |
| **Idle & unused resources** | Running but doing nothing (idle) vs never used (unallocated) |
| **Budgets** | Spend limits with alerts when you approach/exceed them |
| **Cost anomalies** | ML flags a sudden unexpected spike |
| **Recommendations** | Rightsizing, idle shutdown, savings suggestions |
| **AI workload cost** | Visibility into AI/ML spend (e.g. Bedrock, GPU) |

---

## 🤔 Why DevOps Engineers Should Care

| Without CCM | With CCM |
|-------------|----------|
| Surprise bill at month-end | See spend daily, by service/team |
| "Who left that running?" | Idle/unused resources flagged automatically |
| EKS cost is one big number | Cost broken down per namespace/workload |
| React after overspend | Budget alerts + anomaly detection warn you early |
| Guess at savings | Concrete rightsizing recommendations |

> **The big idea:** you can't optimize what you can't see. CCM gives DevOps the cost visibility that used to live only with finance — so engineers can fix waste directly.

---

## 📁 Project Structure

```
Episode-13 (Harness Cloud & AI Cost Management)/
├── Readme.md                 ← This file (concepts + roadmap)
├── DEPLOY-STEPS.md           ← Step-by-step CCM setup + demo
└── sample-workload/
    └── k8s/
        └── cost-demo.yaml    ← A deliberately over-provisioned Deployment
                                 (shows up as an idle/rightsizing recommendation)
```

> There's no application to build in Episode 13 — CCM is a Harness **platform + AWS configuration** episode. The small K8s workload exists only to demonstrate Kubernetes cost + a rightsizing recommendation.

---

## 💰 Cost & Free Tier

Harness CCM is **Free Forever** for organizations under **$250K/month** cloud spend — so your free-tier account qualifies. CCM reads your existing AWS bill; it doesn't add cost. The only spend is whatever AWS resources you already run (EKS, EC2, etc.), which you destroy after the demo.

---

## 🛠️ Technologies

| Category | Technology |
|----------|-----------|
| **FinOps** | Harness Cloud Cost Management (CCM) |
| **Cloud** | AWS (Cost & Usage Report, cross-account IAM role) |
| **Kubernetes cost** | EKS + Harness Delegate (K8s cost collection) |
| **Governance** | Budgets, anomaly detection, perspectives |

---

## 📋 How to Use

See **[DEPLOY-STEPS.md](./DEPLOY-STEPS.md)** for the full CCM setup and demo.

---

> 🎬 Previous: [Episode 12 - Feature Management](../Episode-12%20(Harness%20Feature%20Management%20%26%20Experimentation)/Readme.md)
> 🎬 Next: Episode 14 - Service Reliability Management (SRM)
