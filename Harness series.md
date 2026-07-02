

# Harness CI/CD Zero to Hero (10 Episodes)

## Episode 1: Introduction to Harness & Enterprise CI/CD

**Goal:** Understand why Harness exists before using it.

Topics:

* What is Harness?
* Evolution of CI/CD
* Problems with Jenkins
* Why enterprises are moving to Harness
* CI vs CD vs GitOps
* Harness Architecture
* SaaS vs Self-Managed
* Harness Modules overview (CI, CD, GitOps, FF, CCM, STO, etc.)
* Real-world architecture
* Course roadmap

**Demo:**

* Create Harness account
* Explore the dashboard

---

# Episode 2: Harness Fundamentals

Topics:

* Account
* Organization
* Project
* RBAC
* Users
* Roles
* Resource Groups
* API Keys
* Delegates
* Connectors
* Secrets
* Variables

**Demo:**

* Build a complete Harness project from scratch.

---

# Episode 3: Harness Delegate & Connectors

Topics:

* Delegate Architecture
* Kubernetes Delegate
* Docker Delegate
* VM Delegate
* Delegate Scaling
* Delegate High Availability
* Delegate Troubleshooting

Connectors:

* GitHub
* GitLab
* Bitbucket
* Docker Hub
* Amazon ECR
* AWS
* Azure
* GCP
* Kubernetes
* Helm
* Artifact Registry

**Demo:**

* Install Delegate on Kubernetes.
* Configure all required connectors.

---

# Episode 4: Build Your First Enterprise CI Pipeline

Topics:

* Pipeline
* Stages
* Steps
* Variables
* Runtime Inputs
* Expressions
* Git Experience
* Templates

Pipeline Flow:

* Clone Repository
* Install Dependencies
* Unit Test
* Build Application
* Docker Build
* Docker Buildx
* Multi-stage Dockerfile
* Image Tagging
* Push Image to Docker Hub
* Push Image to Amazon ECR

**Demo:**
Build a production-ready CI pipeline.

---

# Episode 5: Advanced CI & DevSecOps

Topics:

* Caching

  * Maven
  * npm
  * Gradle
  * Go
  * Python
* Matrix Build
* Parallel Execution
* Performance Optimization
* Triggers

  * Git Push
  * Pull Request
  * Webhook
  * Cron

Security:

* Trivy
* SonarQube
* Gitleaks
* OWASP Dependency Check

**Demo:**
Secure CI pipeline with automated security scanning.

---

# Episode 6: Continuous Delivery to Kubernetes

Topics:

* Introduction to CD
* Kubernetes Deployment
* Kubernetes Connector
* Manifest
* Namespace
* Service
* ConfigMap
* Secret
* Deployment
* Rollout
* Health Check

Deployment Strategies:

* Rolling
* Blue-Green
* Canary
* Recreate

Rollback:

* Manual
* Automatic

**Demo:**
Deploy a Java/Spring Boot application to Kubernetes.

---

# Episode 7: Helm, Amazon EKS & Amazon ECS Deployment

Topics:

* Helm Charts
* Chart.yaml
* Values.yaml
* Templates
* Upgrade
* Rollback

Amazon EKS:

* IAM
* EKS Connector
* Production Deployment

Amazon ECS:

* Task Definition
* Service
* Fargate
* Auto Scaling

**Demo:**
Deploy the same application to both EKS and ECS.

---

# Episode 8: Enterprise Security & Governance

Topics:

* Secret Manager
* AWS Secrets Manager
* HashiCorp Vault
* Kubernetes Secrets
* Encrypted Variables
* Approval Gates
* Manual Approval
* Jira Approval
* Email Approval
* OPA
* Governance
* Policy as Code

**Demo:**
Build a production approval workflow with secure secret management.

---

# Episode 9: GitOps & Observability

Topics:

* What is GitOps?
* Harness GitOps
* Argo CD Integration
* Sync
* Rollback
* Auto Sync

Observability:

* Prometheus
* Grafana
* Datadog
* New Relic

Notifications:

* Slack
* Email
* Microsoft Teams

**Demo:**
Deploy an application using GitOps and monitor it with dashboards and alerts.

---

# Episode 10: Complete Enterprise Project (End-to-End)

This is the capstone project where everything comes together.

**Project Flow:**

GitHub Repository
⬇️
Harness CI Pipeline
⬇️
SonarQube Code Scan
⬇️
Gitleaks Secret Scan
⬇️
Trivy Image Scan
⬇️
Docker Multi-stage Build
⬇️
Push to Amazon ECR
⬇️
Deploy to Amazon EKS using Helm
⬇️
Manual Approval Gate
⬇️
Canary Deployment
⬇️
Health Verification
⬇️
Prometheus & Grafana Monitoring
⬇️
Slack Notifications
⬇️
Automatic Rollback on Failure

### Final Outcome

By the end of these 10 episodes, your audience will have built an enterprise-grade CI/CD platform covering:

* Harness CI
* Harness CD
* Harness GitOps
* Kubernetes
* Helm
* Amazon EKS
* Amazon ECS
* Docker
* Amazon ECR
* GitHub Integration
* SonarQube
* Trivy
* Gitleaks
* OWASP Dependency Check
* AWS Secrets Manager
* HashiCorp Vault
* OPA Policies
* Approval Gates
* Canary & Blue-Green Deployments
* Prometheus
* Grafana
* Datadog
* New Relic
* Production Rollbacks
* Enterprise CI/CD Best Practices

