# Harness CI/CD — Interview Questions & Answers


---

## Basics

**Q: What is Harness?**
Harness is a platform that handles the whole software delivery process in one place — building code, deploying it, GitOps, security scans, cost management, feature flags, all of it. Instead of stitching together Jenkins plus a bunch of plugins plus separate tools, you get it all under one roof with a clean UI and YAML pipelines.

**Q: Why do companies move from Jenkins to Harness?**
With Jenkins you end up maintaining the Jenkins server, dozens of plugins, and writing a lot of Groovy. Everything is a plugin — security scanning, approvals, Kubernetes, rollback — and plugins break. Harness has most of that built in. The two things people really move for are automatic rollback and verification: Harness can watch your deployment after it goes out and roll it back on its own if something looks wrong. Jenkins can't do that out of the box.

**Q: What's the difference between CI, CD, and GitOps?**
CI is building and testing your code every time someone pushes — making sure it compiles and the tests pass, then producing an artifact like a Docker image. CD is taking that artifact and getting it onto your servers or cluster, usually with approvals and a rollback plan. GitOps is a style of CD where Git is the single source of truth — you change a file in Git, and an agent in the cluster pulls that change and makes the cluster match. Nobody runs kubectl by hand.

---

## Delegate

**Q: What is a Harness Delegate?**
It's a small worker you install inside your own environment — your cluster, your VPC. It does the actual work: cloning repos, building, running kubectl and helm, deploying. Harness itself never reaches into your network. The delegate reaches out to Harness, asks "do you have any work for me?", does the task locally, and sends the results back.

**Q: Why is the delegate secure? Doesn't it open a hole in my firewall?**
No, and that's the point. The connection is outbound only — the delegate calls out to Harness over HTTPS. Harness never initiates a connection into your network, so there are no inbound ports to open. Your code and your secrets stay on your side. That's why security teams are comfortable with it.

**Q: What types of delegates are there?**
Kubernetes delegate is the common one for production — it runs as a pod and scales naturally. There's a Docker delegate for a single VM or EC2 box, an ECS delegate that runs as a Fargate task, and you can install the Kubernetes one via a Helm chart. In my course I used the Docker delegate on EC2 for early episodes and the Kubernetes delegate on EKS from Episode 6 onward.

**Q: How do you make the delegate highly available?**
You run more than one replica. If you run a single delegate and it dies mid-deployment, that's an outage. So in production you run two or more, let them autoscale, and the tasks get distributed across whichever ones are available. If one dies, the others pick up the work.

---

## Connectors, Secrets, Variables

**Q: What is a connector?**
A connector is a reusable, saved connection to an external system — GitHub, Docker Hub, ECR, AWS, Kubernetes, Prometheus. You set it up once with the credentials, and every pipeline reuses it. In my course the GitHub connector I made in Episode 1 is still used in Episode 10 untouched.

**Q: How does Harness handle secrets?**
Harness has a built-in secret manager that's free, and it can also connect to AWS Secrets Manager, HashiCorp Vault, Azure Key Vault, and others. Secrets are always stored encrypted and only decrypted at runtime by the delegate — the Harness UI never sees the raw value. In logs, secret values are automatically masked. You reference a secret with the expression `<+secrets.getValue("my_secret")>`.

**Q: Why use OIDC instead of AWS access keys?**
Access keys are long-lived — if one leaks, someone has your account until you rotate it. With OIDC, Harness proves its identity to AWS directly and gets temporary credentials. Nothing long-lived is stored anywhere. It's the production-grade way to connect to AWS.

**Q: What's a Harness expression?**
It's how you reference dynamic values, written as `<+...>`. For example `<+pipeline.sequenceId>` is the build number, `<+artifact.image>` is the image you just built, `<+variable.aws_region>` is a variable you defined. Harness replaces these with real values at runtime.

---

## Pipelines

**Q: What's the structure of a Harness pipeline?**
A pipeline has stages, stages have steps. A CI stage might clone the code, run tests, build the image, push to ECR. A CD stage deploys it. You can run stages or steps in parallel, add approval stages, and attach failure strategies so that if something fails, it rolls back automatically.

**Q: What's the difference between a CI stage and a CD (Deployment) stage?**
A CI stage is about building and testing — it runs on build infrastructure (Harness Cloud or your own cluster) and produces an artifact. A CD/Deployment stage is about releasing — it references a Service (what you deploy), an Environment (where), and an Infrastructure (how to reach it), and runs steps like K8sRollingDeploy or HelmDeploy.

**Q: Service vs Environment vs Infrastructure — explain simply.**
Service is *what* you're deploying — the app, its manifests, and the artifact. Environment is *where* — dev, staging, prod. Infrastructure is *how you reach the target* — which delegate, which cluster, which namespace. The pipeline ties them together.

**Q: What is Harness Cloud vs KubernetesDirect for CI builds?**
Harness Cloud means the build runs on Harness-managed servers — free, zero setup, great for learning. KubernetesDirect means the build runs on your own cluster — your code never leaves your network, which is what banks and regulated companies need for compliance. In my course, Episodes 1-8 used Harness Cloud, and 9-10 switched to KubernetesDirect to show the MNC way.

---

## Deployment Strategies & Rollback

**Q: What deployment strategies does Harness support?**
Rolling, blue-green, canary, and recreate. Rolling replaces pods gradually with zero downtime. Blue-green keeps the old version alive and switches traffic instantly, so rollback is immediate. Canary sends a small slice of traffic to the new version first, you verify, then go 100%. Recreate kills the old and starts the new — brief downtime, used rarely.

**Q: How does rollback work in Harness?**
Two ways — manual and automatic. For Kubernetes, Harness uses the cluster's own revision history, so `K8sRollingRollback` goes back to the last good version. The powerful part is automatic rollback: if a step fails or verification detects a problem, the pipeline's failure strategy triggers the rollback section on its own. In my Episode 10 I showed this — I broke a service, verification caught it, and Harness reverted the Git commit and re-synced automatically.

**Q: What's the `:stable` tag pattern?**
It's a simple rollback trick for Docker deployments. Every successful deploy also tags the image as `:stable`. If a new deploy fails its health check, you redeploy `:stable` to get back the last known-good version. The `:stable` tag only updates after the health check passes.

---

## GitOps

**Q: What is GitOps and how does Harness do it?**
GitOps means Git is the single source of truth for what should be running. Harness GitOps uses Argo CD under the hood through a GitOps Agent you install in the cluster. The agent watches your Git repo and pulls changes into the cluster — a pull model, not a push. If someone manually changes something in the cluster, the agent notices the drift and corrects it back to match Git.

**Q: Push vs pull deployment — what's the difference?**
Push is a pipeline running kubectl/helm to push changes into the cluster from outside. Pull is GitOps — an agent inside the cluster pulls the desired state from Git. Pull is more secure because the cluster credentials never leave the cluster, and it self-heals drift.

**Q: What's drift, and how does GitOps handle it?**
Drift is when the cluster no longer matches what's in Git — someone hand-edited a resource, or something changed outside the pipeline. The GitOps agent continuously compares the cluster to Git, and when it sees drift it syncs the cluster back to the Git state automatically.

---

## Security & Governance

**Q: How do you add security scanning to a pipeline?**
You add scanning steps — Trivy for container vulnerabilities, Gitleaks for secrets, SonarQube for code quality, OWASP/OSV for dependency CVEs, Checkov for infrastructure misconfig. The trick is to run them in parallel so security costs you no extra pipeline time, and set them to fail the build on critical findings.

**Q: What is OPA / Policy as Code in Harness?**
OPA lets you write governance rules as code in a language called Rego, and Harness checks your pipeline against them. Things like "every production deploy must have an approval stage", "no deploys on Friday after 5 PM", "containers must have CPU and memory limits". If a pipeline breaks a rule, Harness blocks it before it runs.

**Q: What are approval gates?**
A pause in the pipeline where a human has to click approve before it continues — usually before a production deploy. You can require a minimum number of approvers, restrict who can approve, and set a timeout so it auto-rejects if nobody responds.

---

## Observability & Verification

**Q: What is Continuous Verification?**
After a deployment, Harness watches the app's metrics — from Prometheus, Elasticsearch, and so on — and compares the new version's behavior to the baseline. If it sees anomalies like pods crash-looping or error rates spiking, it automatically rolls back. The key idea: a green pipeline doesn't mean a healthy app, so Harness verifies the app is actually healthy after deploy.

**Q: What's a Monitored Service?**
It's the thing that connects a service and environment to its health sources (Prometheus, Elasticsearch). It's what powers Continuous Verification — it tells Harness where to pull the metrics from to judge whether a deploy is healthy.

---

## The Other Modules (11-15)

**Q: What is Harness Code Repository?**
It's Git hosting built into Harness — repos, branches, pull requests, code reviews, and branch protection rules, all in the same platform as your pipelines. So you can require a review and a passing CI check before anyone merges to main, without using an external Git provider.

**Q: What is Feature Management (FME)?**
Feature flags. You deploy a feature hidden behind a switch, then turn it on from the Harness dashboard — for one user, then 10% of traffic, then everyone — without redeploying. And if it misbehaves, you flip it off in one second. It separates deploy from release.

**Q: What is Cloud Cost Management (CCM)?**
It's the FinOps module. It reads your AWS bill and your Kubernetes usage and shows exactly where the money goes — by service, team, namespace. It finds idle and over-provisioned resources, sets budgets, flags cost anomalies, and gives rightsizing recommendations. DevOps engineers use it to actually cut the bill, not just stare at it.

**Q: What is Service Reliability Management (SRM)?**
It's about reliability after deployment — SLOs, SLIs, and error budgets. You define what "healthy" means for a service, Harness tracks it, and when you start burning your error budget it warns you. The point is that a successful deploy doesn't mean the service is reliable.

**Q: What is Resilience / Chaos testing?**
You deliberately break things in a controlled way — kill pods, stress CPU, inject network failures — to see how your system responds and recovers. The idea is you'd rather discover how your system fails in a test than find out during a real production incident.

---

## Common Scenario Questions

**Q: A deployment went bad in production. Walk me through what happens with Harness.**
If I set it up properly, I don't have to do anything manually. The pipeline has a verification step after deploy and a failure strategy. Verification compares metrics to the baseline, spots the problem — say pods crash-looping — and the failure strategy triggers the rollback section, which reverts to the last good version. For GitOps, it reverts the Git commit and re-syncs. I get a Slack notification saying it failed and rolled back.

**Q: How do you keep secrets out of your Git repo and manifests?**
I never put real values in Git. Secrets live in a secret manager — Harness built-in, AWS Secrets Manager, or Vault — and I reference them with `<+secrets.getValue(...)>`. One important detail: in Kubernetes, Harness only resolves those expressions in the values.yaml, not in raw manifests, so the expression goes in values.yaml and the manifest uses Go templating to pull it in.

**Q: Your pipeline says "service not found" — how do you debug it?**
First I check the service ID the pipeline references actually matches a real service ID in the project — Harness strips special characters, so a service named `feature-flags-app` gets the ID `featureflagsapp`, and that mismatch is a common cause. Then I check scope — is it a project, org, or account resource — and whether the pipeline is reading the right branch if it's stored in Git.

**Q: How do you reduce Docker build time in CI?**
Layer caching. Docker builds layers top to bottom and reuses unchanged ones, so I put the things that rarely change — like dependency installs — early in the Dockerfile, and the code that changes often later. In Harness I also enable build caching and run independent steps in parallel.

---

## Quick One-Liners (rapid fire)

- **Delegate** → worker in your environment, outbound-only connection.
- **Connector** → reusable saved connection to an external system.
- **Secret expression** → `<+secrets.getValue("name")>`.
- **Build number** → `<+pipeline.sequenceId>`.
- **Artifact image** → `<+artifact.image>` (only resolves in values.yaml for K8s).
- **Rolling** → gradual, zero downtime. **Blue-green** → instant switch, instant rollback. **Canary** → small % first.
- **GitOps** → Git is truth, agent pulls, self-heals drift.
- **CV** → verifies the app is healthy after deploy, auto-rolls back.
- **OPA** → governance rules as code, blocks bad pipelines.
- **CCM** → FinOps, find and cut cloud waste.
