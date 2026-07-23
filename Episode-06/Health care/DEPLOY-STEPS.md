# 🚀 Episode 6, Topic 1 — Deploy Healthcare Website to EC2

## Flow

```
Push code → Import pipeline → Run → Image in ECR → Docker container on EC2 → http://EC2-IP
```

---

## Prerequisites (Already Done)

| What | Episode |
|------|---------|
| GitHub connector (`account.Github`) | 1 |
| AWS OIDC connector (`account.aws_account`) | 3 |
| Secret: `aws_access_key_id` | 3 |
| Secret: `aws_secret_access_key` | 3 |
| Variable: `aws_account_id` | 4 |
| Variable: `aws_region` | 3 |

---

## Step 1: Create EC2 Instance

1. AWS Console → EC2 → Launch Instance
2. Name: `harness-cd-delegate`
3. OS: Amazon Linux 2023
4. Type: `t2.medium` (2 CPU, 4 GB)
5. Key pair: Create or use existing
6. **IAM Role: Attach Admin Role** (Instance Profile)
7. Security Group: Allow SSH (22) + HTTP (5000)
8. Launch → Wait for Running ✅

---

## Step 2: SSH into EC2 + Install Docker

```bash
ssh -i your-key.pem ec2-user@EC2-PUBLIC-IP

sudo dnf update -y
sudo dnf install -y docker
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER
newgrp docker
docker --version
```

---

## Step 3: Install Docker Delegate (CD Level)

**In Harness UI:**
1. Account: `yaswanth.arumulla` → Organization: `default` → Project: `HarnessCICDZerotoHero`
2. Go to Project Settings → **Delegates**
3. You'll see: "There are no Delegates in your project"
4. Click **+ New Delegate**
5. Select **Docker**
6. Name: `cd-docker-delegate`
7. Copy the docker run command shown in Harness UI
8. SSH into your EC2 and run the command (with modifications below)

**Modify the command before running:**
- Remove `--network host` (not needed for CD)
- Remove any `DELEGATE_TAGS` line (not needed for CD)
- Add `-v /var/run/docker.sock:/var/run/docker.sock`

**Final command on EC2:**

```bash
docker run -d --cpus=1 --memory=2g \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -e DELEGATE_NAME=cd-docker-delegate \
  -e NEXT_GEN="true" \
  -e DELEGATE_TYPE="DOCKER" \
  -e ACCOUNT_ID=YOUR_ACCOUNT_ID \
  -e DELEGATE_TOKEN=YOUR_TOKEN \
  -e MANAGER_HOST_AND_PORT=https://app.harness.io \
  harness/delegate:latest
```

**NO `--network host`, NO tags, NO Runner — CD only!**

| | Episode 3 (CI) | Episode 6 (CD) |
|---|---|---|
| `--network host` | YES | NO |
| Tags | `linux-amd64` | None |
| Docker Runner | YES (port 3000) | NO |
| Purpose | Build code | Deploy containers |

Wait 2 min → Harness UI → Delegates → `cd-docker-delegate` → **Connected** ✅

---

## Step 4: Push Code to GitHub

```bash
git add .
git commit -m "Episode 6: Healthcare website CD"
git push origin master
```

---

## Step 5: Import Pipeline

1. Pipelines → Import from Git
2. Pipeline Name: `episode6-healthcare-docker-cd`
3. Connector: `Github`
4. Repo: `Harness-CI-CD-Zero-to-Hero`
5. Branch: `master`
6. YAML Path: `Episode-06/Health care/.harness/pipeline-docker-cd.yaml`
7. Import

---

## Step 6: Run Pipeline

1. Run Pipeline → Branch: `master`
2. Watch:

```
Stage 1: Build & Push to ECR ✅
Stage 2: Deploy to EC2 ✅
  ├── Deploy Container
  ├── Health Check (HTTP 200)
  └── Tag :stable
Stage 3: Approval ⏸️
Stage 4: Cleanup ✅
```

---

## Step 7: Access Website

```
http://EC2-PUBLIC-IP:5000
```

Open in browser → Healthcare website visible ✅

API endpoints:
```
http://EC2-PUBLIC-IP:5000/health    → {"status": "healthy"}
http://EC2-PUBLIC-IP:5000/api/doctors → Doctor list (JSON)
http://EC2-PUBLIC-IP:5000/api/services → Services list (JSON)
```

---

## Test Rollback

1. Run pipeline → success ✅ (`:stable` tagged)
2. Add garbage text in `app.py` (like `erxtcfgvhbjkmle` between imports)
3. Push → Run pipeline
4. Stage 1: Image builds fine ✅ (Python doesn't check syntax at build)
5. Stage 2: Container starts → Flask crashes on bad syntax → `/health` returns no response → Health check FAILS → **Rollback triggers** → pulls `:stable` → old version back ✅

---

## Cleanup

```bash
# Pipeline does this automatically after approval
# Or manually:
docker stop healthcare-website && docker rm healthcare-website
```

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| "No eligible delegates" | Check delegate running: `docker ps` |
| Website not loading | Security Group → allow port 80 |
| "permission denied" docker | `sudo usermod -aG docker $USER && newgrp docker` |
| Health check fails | Check container is running: `docker ps` |
