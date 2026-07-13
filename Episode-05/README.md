# Episode 5: Advanced CI & DevSecOps

## 🎯 Goal
Make your CI pipeline FAST (caching, parallel builds) and SECURE (security scanning).
Like adding turbo boost AND a security alarm to your car.

---

## 📚 Topics Covered

### 1. Caching (Make Builds FAST)

**Problem Without Caching:**
```
Every build downloads ALL dependencies from scratch:

Build 1: Download 500MB of dependencies (5 minutes)
Build 2: Download 500MB of dependencies (5 minutes) ← SAME files!
Build 3: Download 500MB of dependencies (5 minutes) ← SAME files!

Total wasted time: 10 minutes per day × 365 days = 60+ HOURS/year wasted!
```

**Solution With Caching:**
```
Build 1: Download 500MB of dependencies (5 minutes) → Save to cache
Build 2: Load from cache (10 seconds) ✅
Build 3: Load from cache (10 seconds) ✅

Saved: 60+ hours per year!
```

**Cache Keys by Language:**

| Language | Cache Key | What's Cached |
|----------|-----------|---------------|
| Maven | `maven-{{ checksum "pom.xml" }}` | `/root/.m2/repository` |
| npm | `npm-{{ checksum "package-lock.json" }}` | `node_modules` |
| Gradle | `gradle-{{ checksum "build.gradle" }}` | `/root/.gradle/caches` |
| Go | `go-{{ checksum "go.sum" }}` | `/root/go/pkg/mod` |
| Python | `pip-{{ checksum "requirements.txt" }}` | `/root/.cache/pip` |

#### Maven Cache
```yaml
caching:
  enabled: true
  paths:
    - /root/.m2/repository
# OR use S3 cache:
- step:
    type: RestoreCacheS3
    name: Restore Maven Cache
    spec:
      connectorRef: account.aws_account
      region: us-east-1
      bucket: my-build-cache
      key: maven-{{ checksum "pom.xml" }}
      archiveFormat: Tar
      failIfKeyNotFound: false
# After build:
- step:
    type: SaveCacheS3
    name: Save Maven Cache
    spec:
      connectorRef: account.aws_account
      region: us-east-1
      bucket: my-build-cache
      key: maven-{{ checksum "pom.xml" }}
      sourcePaths:
        - /root/.m2/repository
      archiveFormat: Tar
```

#### npm Cache
```yaml
caching:
  enabled: true
  paths:
    - node_modules
# OR S3:
# key: npm-{{ checksum "package-lock.json" }}
# sourcePaths: [node_modules]
```

#### Gradle Cache
```yaml
caching:
  enabled: true
  paths:
    - /root/.gradle/caches
    - /root/.gradle/wrapper
# key: gradle-{{ checksum "build.gradle" }}
```

#### Go Cache
```yaml
caching:
  enabled: true
  paths:
    - /root/go/pkg/mod
    - /root/.cache/go-build
# key: go-{{ checksum "go.sum" }}
```

#### Python Cache
```yaml
caching:
  enabled: true
  paths:
    - /root/.cache/pip
    - .venv
# key: pip-{{ checksum "requirements.txt" }}
```

#### Rust Cache
```yaml
caching:
  enabled: true
  paths:
    - /root/.cargo/registry
    - target
# key: rust-{{ checksum "Cargo.lock" }}
```

---

### 2. Matrix Builds (Test Multiple Versions)

```
Problem: Your app should work with Java 11, 17, and 21.
Testing one at a time = 3 separate pipelines = messy

Solution: Matrix Build = Test ALL versions in parallel!

┌───────────────────────────────────────────────┐
│  Matrix Build                                  │
│                                                │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐      │
│  │ Java 11 │  │ Java 17 │  │ Java 21 │      │
│  │  Test   │  │  Test   │  │  Test   │      │
│  │  Build  │  │  Build  │  │  Build  │      │
│  └────┬────┘  └────┬────┘  └────┬────┘      │
│       │             │             │           │
│       └─────────────┼─────────────┘           │
│                     ▼                          │
│              All passed? ✅                    │
│              Continue pipeline                 │
└───────────────────────────────────────────────┘
```

#### Java Matrix (Multiple JDK Versions)
```yaml
- step:
    type: Run
    name: Test
    identifier: test
    spec:
      image: maven:<+matrix.mavenVersion>
      command: mvn test
    strategy:
      matrix:
        mavenVersion:
          - "3.8-eclipse-temurin-11"
          - "3.9-eclipse-temurin-17"
          - "3.9-eclipse-temurin-21"
        maxConcurrency: 3
```

#### Node.js Matrix (Multiple Node Versions)
```yaml
- step:
    type: Run
    name: Test Node
    identifier: test_node
    spec:
      image: node:<+matrix.nodeVersion>
      command: npm ci && npm test
    strategy:
      matrix:
        nodeVersion:
          - "18-alpine"
          - "20-alpine"
          - "22-alpine"
        maxConcurrency: 3
```

#### Python Matrix (Multiple Python Versions)
```yaml
- step:
    type: Run
    name: Test Python
    identifier: test_python
    spec:
      image: python:<+matrix.pythonVersion>
      command: pip install -r requirements.txt && pytest
    strategy:
      matrix:
        pythonVersion:
          - "3.10-slim"
          - "3.11-slim"
          - "3.12-slim"
        maxConcurrency: 3
```

#### Go Matrix (Multiple Go Versions)
```yaml
- step:
    type: Run
    name: Test Go
    identifier: test_go
    spec:
      image: golang:<+matrix.goVersion>
      command: go test ./...
    strategy:
      matrix:
        goVersion:
          - "1.21"
          - "1.22"
          - "1.23"
        maxConcurrency: 3
```

#### Multi-Dimension Matrix (Version + OS)
```yaml
- step:
    type: Run
    name: Cross-Platform Test
    identifier: cross_test
    spec:
      command: npm test
    strategy:
      matrix:
        nodeVersion:
          - "18"
          - "20"
        os:
          - "linux"
          - "windows"
        maxConcurrency: 4
        # Runs: 18-linux, 18-windows, 20-linux, 20-windows (4 parallel)
```

---

### 3. Parallel Execution

```
SEQUENTIAL (Slow):
Step 1 (2 min) → Step 2 (2 min) → Step 3 (2 min) = 6 minutes total

PARALLEL (Fast):
Step 1 (2 min) ─┐
Step 2 (2 min) ─┼─ = 2 minutes total!
Step 3 (2 min) ─┘
```

---

### 4. Triggers

| Trigger Type | When It Runs | Use Case |
|-------------|--------------|----------|
| Git Push | Code pushed to master | Every commit gets tested |
| Pull Request | PR opened/updated | Review before merge |
| Cron | Scheduled (e.g. daily 2 AM) | Nightly security scans |
| Webhook | External event | Third-party integrations |

#### Git Push Trigger
```yaml
trigger:
  name: On Push to Master
  identifier: on_push_master
  type: Webhook
  spec:
    type: Github
    spec:
      type: Push
      spec:
        connectorRef: account.Github
        repoName: Harness-CI-CD-Zero-to-Hero
        autoAbortPreviousExecutions: true
      payloadConditions:
        - key: targetBranch
          operator: Equals
          value: master
```

#### Pull Request Trigger
```yaml
trigger:
  name: On Pull Request
  identifier: on_pull_request
  type: Webhook
  spec:
    type: Github
    spec:
      type: PullRequest
      spec:
        connectorRef: account.Github
        repoName: Harness-CI-CD-Zero-to-Hero
        autoAbortPreviousExecutions: true
        actions:
          - Open
          - Reopen
          - Synchronize
      payloadConditions:
        - key: targetBranch
          operator: Equals
          value: master
```

#### Cron Trigger (Scheduled — Daily Security Scan)
```yaml
trigger:
  name: Daily Security Scan
  identifier: daily_security_scan
  type: Scheduled
  spec:
    type: Cron
    spec:
      expression: "0 2 * * *"
```

#### How to Create in Harness UI:
1. Go to: Pipelines → devsecops-pipeline → **Triggers** tab
2. Click **+ New Trigger**
3. Choose type (Webhook or Scheduled)
4. Configure conditions (branch, actions, cron expression)
5. Save ✅

---

### 5. Security Scanning (DevSecOps)

```
DevSecOps = Development + Security + Operations

Traditional:
  Code → Build → Deploy → Security team finds issues (TOO LATE!)

DevSecOps:
  Code → Security Scan → Build → Security Scan → Deploy
         ↑ Find issues EARLY = Cheaper to fix!
```

#### 4 Security Tools We Use:

| Tool | What It Scans | Example Finding |
|------|---------------|-----------------|
| **Gitleaks** | Secrets in code | 🔑 AWS Access Key found in config.py line 15 |
| **SonarQube** | Code quality & bugs | 🐛 Null pointer on line 42, SQL injection on line 88 |
| **Trivy** | Docker image CVEs | ⚠️ CRITICAL: log4j-2.14.0 has Remote Code Execution |
| **OWASP** | Dependency vulnerabilities | ⚠️ HIGH: spring-core-5.3.0 has CVE-2022-22965 |

---

### Pipeline Flow Visualization

```
┌──────────────────────────────────────────────────────────────┐
│  DEVSECOPS PIPELINE (5 Stages)                                │
│                                                                │
│  STAGE 1: Build & Test                                        │
│  ┌──────────────────┐                                         │
│  │ npm ci (cached)  │                                         │
│  └────────┬─────────┘                                         │
│           ▼                                                    │
│  ┌────────────┐ ┌────────────┐ ┌────────────┐ ┌───────────┐ │
│  │ Lint Check │ │ Unit Tests │ │ Gitleaks   │ │ SonarQube │ │
│  │            │ │ + Coverage │ │ (secrets)  │ │ (quality) │ │
│  └─────┬──────┘ └─────┬──────┘ └─────┬──────┘ └─────┬─────┘ │
│        └───────────────┼──────────────┼───────────────┘       │
│                        ▼ PARALLEL                              │
│                                                                │
│  STAGE 2: Security Scanning                                   │
│  ┌──────────────────┐                                         │
│  │ Docker Build     │                                         │
│  └────────┬─────────┘                                         │
│           ▼                                                    │
│  ┌─────────────────┐  ┌─────────────────────┐                │
│  │ Trivy           │  │ OWASP/npm audit     │                │
│  │ (image CVEs) 🐳 │  │ (dependencies) 📦   │                │
│  └────────┬────────┘  └────────┬────────────┘                │
│           └────────┬───────────┘                              │
│                    ▼ PARALLEL                                  │
│  ┌──────────────────┐                                         │
│  │ Security Summary │                                         │
│  └────────┬─────────┘                                         │
│           ▼                                                    │
│  STAGE 3: Push to ECR                                         │
│  ┌──────────────────┐                                         │
│  │ Create ECR Repo  │                                         │
│  └────────┬─────────┘                                         │
│           ▼                                                    │
│  ┌──────────────────┐                                         │
│  │ Push to ECR 🚀   │  (OIDC connector)                      │
│  └────────┬─────────┘                                         │
│           ▼                                                    │
│  STAGE 4: Approval ⏸️                                         │
│  ┌──────────────────────────────────────────┐                 │
│  │ "Delete images?" → APPROVE / REJECT      │                 │
│  └────────┬─────────────────────────────────┘                 │
│           ▼ (only if approved)                                 │
│                                                                │
│  STAGE 5: Cleanup                                             │
│  ┌──────────────────┐                                         │
│  │ Delete ECR Repo  │                                         │
│  └──────────────────┘                                         │
│                                                                │
│  Result: Secure, tested, scanned image on ECR! 🛡️🚀          │
└──────────────────────────────────────────────────────────────┘
```

---

## 🚀 Deployment Steps (How to Run This Pipeline)

### Prerequisites (already done in previous episodes)

| What | Where | Episode | Link |
|------|-------|---------|------|
| GitHub connector | Account Settings → Connectors | Episode 1 | [Episode 1 — Deploy Steps](../Episode-01/hello-world-app/DEPLOY-STEPS.md) |
| AWS connector (OIDC) | Account Settings → Connectors | Episode 3 | [Episode 3 — Connector Setup](../Episode-03/README.md#connector-3-aws--🆕-create-now) |
| aws_access_key_id secret | Project Settings → Secrets | Episode 3 | [Episode 3 — Terraform README](../Episode-03/terraform-project/README.md#step-2-get-aws-access-key--secret-key) |
| aws_secret_access_key secret | Project Settings → Secrets | Episode 3 | [Episode 3 — Terraform README](../Episode-03/terraform-project/README.md#step-3-add-secrets-in-harness) |
| aws_account_id variable | Project Settings → Variables | Episode 4 | [Episode 4 — Deployment Steps](../Episode-04/README.md#step-1-add-aws-account-id-variable) |

### New Setup for Episode 5

1. **Create SonarQube secret** (optional):
   - Project Settings → Secrets → + New Secret → Text
   - Name: `sonar_token`
   - Value: token from SonarQube (My Account → Security → Generate)

2. **Create SonarQube variable** (optional):
   - Project Settings → Variables → + New Variable
   - Name: `sonar_host_url`
   - Value: `http://YOUR-BASTION-IP:9000`

### Step 1: Push Code to GitHub

```bash
git add .
git commit -m "Episode 5: DevSecOps pipeline"
git push origin master
```

### Step 2: Import Pipeline in Harness

1. Pipelines → Import from Git
2. Fill in:
   - Pipeline Name: `devsecops-pipeline`
   - Git Connector: `Github` (account level)
   - Repository: `Harness-CI-CD-Zero-to-Hero`
   - Branch: `master`
   - YAML Path: `Episode-05/node-project/.harness/devsecops-pipeline.yaml`
3. Click Import

### Step 3: Run the Pipeline

1. Click "Run Pipeline"
2. Select branch: `master`
3. Click "Run Pipeline"

### Step 4: Watch 5 Stages Execute

```
Stage 1: Build & Test
  ├── Install Dependencies (npm ci — cached)
  ├── PARALLEL:
  │   ├── Lint Check
  │   ├── Unit Tests + Coverage
  │   ├── Gitleaks (secret detection) 🔑
  │   └── SonarQube (code quality + security)

Stage 2: Security Scanning
  ├── Build Docker Image
  ├── PARALLEL:
  │   ├── Trivy (image CVEs) 🐳
  │   └── OWASP/npm audit (dependencies) 📦
  └── Security Summary

Stage 3: Push to ECR
  ├── Create ECR Repo
  ├── Push to ECR (OIDC)
  └── Pipeline Complete Summary

Stage 4: Approval ⏸️
  └── Click Approve (to delete) or Reject (to keep images)

Stage 5: Delete ECR (after approval)
  └── Delete ECR repo + images
```

### Step 5: Create Triggers (Optional)

1. Pipelines → devsecops-pipeline → Triggers tab
2. Click + New Trigger:
   - **Git Push**: Webhook → GitHub → Push → branch = master
   - **PR trigger**: Webhook → GitHub → Pull Request → target = master
   - **Cron**: Scheduled → `0 2 * * *` (daily 2 AM security scan)

---

## Security Tools Summary

| Tool | What It Checks | Runs In | Image Used |
|------|----------------|---------|------------|
| Gitleaks | Secrets in code | Stage 1 (parallel) | `zricethezav/gitleaks:latest` |
| SonarQube | Code quality, bugs | Stage 1 (parallel) | `sonarsource/sonar-scanner-cli:latest` |
| Trivy | Docker image CVEs | Stage 2 (parallel) | `aquasec/trivy:latest` |
| OWASP/npm audit | Dependency vulns | Stage 2 (parallel) | Built-in (npm audit) |

## Performance Features

| Feature | What It Does | Time Saved |
|---------|-------------|------------|
| npm Caching | Reuses node_modules between builds | 2-3 min/build |
| Parallel Steps (Stage 1) | Lint + Test + Gitleaks + SonarQube run together | ~50% |
| Parallel Steps (Stage 2) | Trivy + OWASP run together | ~50% |

---

## Project Structure

```
Episode-05/
├── README.md                              ← This file
└── node-project/
    ├── package.json                       ← Node.js app
    ├── src/index.js                       ← Express app (3 endpoints)
    ├── src/index.test.js                  ← Jest unit tests
    ├── Dockerfile                         ← Multi-stage, secure, non-root
    ├── sonar-project.properties           ← SonarQube config
    ├── .gitignore
    ├── DEPLOY-STEPS.md                    ← Quick reference
    └── .harness/
        ├── devsecops-pipeline.yaml        ← Main pipeline (5 stages)
        └── triggers.yaml                  ← Trigger examples (reference)
```

---

## ✅ Episode 5 Checklist

- [ ] Understand caching and how it speeds up builds
- [ ] Know cache keys for Maven, npm, Gradle, Go, Python
- [ ] Understand matrix builds for multi-version testing
- [ ] Know how to run steps in parallel
- [ ] Created Git Push trigger
- [ ] Created Pull Request trigger
- [ ] Understand what each security tool does
- [ ] Added Trivy scanning to pipeline
- [ ] Added SonarQube scanning to pipeline
- [ ] Added Gitleaks scanning to pipeline
- [ ] Added OWASP scanning to pipeline
- [ ] Pipeline runs security scans automatically

---

## 📝 Key Takeaways

1. **Cache = Speed** (save hours of download time)
2. **Matrix = Test multiple versions** simultaneously
3. **Parallel = Do multiple things at once** (faster pipeline)
4. **Triggers = Automatic** (push code → pipeline runs)
5. **Security scanning should be EARLY** in the pipeline (shift left)
6. **4 Security Tools**: Gitleaks (secrets), SonarQube (code), OWASP (deps), Trivy (images)

---

> 🎬 Next Episode: [Episode 6 - Continuous Delivery to Kubernetes](../Episode-06/README.md)
