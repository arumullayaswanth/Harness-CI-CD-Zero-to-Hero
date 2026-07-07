# Harness Pipeline Templates

## What is a Template?

```
Without Template: Copy-paste pipeline for each project (10 projects = 10 copies)
With Template:    Create 1 template → use it in all 10 projects
                  Change once → all 10 update automatically
```

---

## Template Types in Harness

| Type | What It Reuses | Example |
|------|---------------|---------|
| Step Template | Single step | "Run Tests" step |
| Stage Template | Group of steps | "Build and Push" stage |
| Pipeline Template | Entire pipeline | Full CI/CD pipeline |

---

## Our Pipeline Template

**File:** `.harness/template-pipeline.yaml`

**What it does:** Complete CI pipeline for ANY language

**Stages:**
```
Stage 1: Build, Test, Push to Docker Hub
Stage 2: Push to Amazon ECR
Stage 3 & 4 (Parallel): Delete Docker Hub + Delete ECR
```

---

## How to Use the Template

### In Harness UI:

1. Go to Project → Templates → + New Template
2. Choose: Pipeline
3. Select: Import from Git
4. YAML Path: `Episode-04/cpp-project/.harness/template-pipeline.yaml`
5. Click Import

### When Using the Template (Creating a Pipeline from it):

1. Pipelines → + Create Pipeline
2. Choose: "Start with Template"
3. Select: "Enterprise CI Pipeline Template"
4. Fill in the inputs (see below)
5. Click Run → Fill all fields → Run Pipeline

**Fill these when running:**

```
Pipeline Variables:
─────────────────
  deploy_version:   1.0.0
  environment:      development (or testing/staging/production)
  app_name:         cpp-harness-app
  dockerfile_path:  Episode-04/cpp-project/Dockerfile
  build_context:    Episode-04/cpp-project
  build_command:    cd Episode-04/cpp-project && mkdir -p build && cd build && cmake .. && make app
  test_command:     cd Episode-04/cpp-project && mkdir -p build && cd build && cmake .. && make tests && ./tests

CI Codebase:
────────────
  Connector:        Github 
  Repository Name:  Harness-CI-CD-Zero-to-Hero
  Build Type:       Git Branch
  Branch Name:      master

Stage: build-and-push:
──────────────────────
  Step: Push to Docker Hub
    Docker Connector: dockerhub 

Stage: push-to-ecr:
────────────────────
  Step: Push to ECR
    AWS Connector:  aws_account 
    Region:         us-east-1
    Account Id:     713939171080 (your AWS account ID)
```

---

## Template Inputs

When you run a pipeline created from this template, you provide these values:

| Input | Description | Example |
|-------|-------------|---------|
| `deploy_version` | Version number | `1.0.0` |
| `environment` | Target environment | `development`, `testing`, `staging`, `production` |
| `app_name` | Application name (used in Docker repo) | `cpp-harness-app` |
| `dockerfile_path` | Path to Dockerfile | `Episode-04/cpp-project/Dockerfile` |
| `build_context` | Docker build context | `Episode-04/cpp-project` |
| `build_command` | How to build the app | `cd Episode-04/cpp-project && mkdir build && cd build && cmake .. && make` |
| `test_command` | How to test the app | `cd Episode-04/cpp-project && mkdir build && cd build && cmake .. && make tests && ./tests` |
| `connectorRef` (codebase) | GitHub connector | `account.Github` |
| `repoName` | GitHub repo | `Harness-CI-CD-Zero-to-Hero` |
| `connectorRef` (Docker) | Docker Hub connector | `dockerhub` |
| `connectorRef` (ECR) | AWS connector | `aws_account` |
| `region` (ECR) | AWS region | `us-east-1` |
| `account` (ECR) | AWS account ID | `713939171080` |

---

## Examples for Different Languages

### C++ (This project)

```
app_name:        cpp-harness-app
build_command:   cd Episode-04/cpp-project && mkdir -p build && cd build && cmake .. && make app
test_command:    cd Episode-04/cpp-project && mkdir -p build && cd build && cmake .. && make tests && ./tests
dockerfile_path: Episode-04/cpp-project/Dockerfile
build_context:   Episode-04/cpp-project
```

### Python

```
app_name:        python-harness-app
build_command:   cd project && pip install -r requirements.txt
test_command:    cd project && pip install -r requirements.txt && pytest -v
dockerfile_path: project/Dockerfile
build_context:   project
```

### Go

```
app_name:        go-harness-app
build_command:   cd project && go build -o main .
test_command:    cd project && go test -v ./...
dockerfile_path: project/Dockerfile
build_context:   project
```

### Java (Maven)

```
app_name:        java-harness-app
build_command:   cd project && mvn clean package -DskipTests
test_command:    cd project && mvn test
dockerfile_path: project/Dockerfile
build_context:   project
```

### Node.js

```
app_name:        node-harness-app
build_command:   cd project && npm install && npm run build
test_command:    cd project && npm install && npm test
dockerfile_path: project/Dockerfile
build_context:   project
```

### Rust

```
app_name:        rust-harness-app
build_command:   cd project && cargo build --release
test_command:    cd project && cargo test
dockerfile_path: project/Dockerfile
build_context:   project
```

---

## How to Deploy the Template

### Step 1: Push template to Git

```bash
git add .
git commit -m "Add pipeline template"
git push origin master
```

### Step 2: Import in Harness

1. Go to Project → Templates
2. Click + New Template → Pipeline
3. Import from Git:
   - Connector: Github
   - Repo: Harness-CI-CD-Zero-to-Hero
   - Branch: master
   - Path: `Episode-04/cpp-project/.harness/template-pipeline.yaml`
4. Click Import

### Step 3: Create pipeline from template

1. Pipelines → + Create Pipeline
2. Click "Start with Template"
3. Select your template
4. Fill in the runtime inputs
5. Save → Run

---

## Benefits of Templates

```
1. Write once, use everywhere
2. Change template → all pipelines using it update
3. Enforces standards across teams
4. New projects get CI pipeline in 2 minutes
5. Consistent tagging, testing, and cleanup across all apps
```

---

## Template vs Regular Pipeline

| | Regular Pipeline | Template Pipeline |
|---|---|---|
| Reusable | ❌ Copy-paste | ✅ One template, many uses |
| Update once | ❌ Update each copy | ✅ Update template, all update |
| Consistency | ❌ Each team does different | ✅ Same standard everywhere |
| Setup time for new project | 30 min | 2 min |
| Inputs | Hardcoded values | Runtime inputs (flexible) |
