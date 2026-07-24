# 🚀 Episode 6, Topic 1 — Deploy Healthcare Website to EC2

## Flow

```
Create Service + Environment in Harness UI → Import Pipeline → Run → EC2-IP:5000
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
5. Key pair: Create or use existing → **Download .pem file**
6. **IAM Role: Attach Admin Role** (Instance Profile)
7. Security Group: Allow SSH (22) + port 5000
8. Launch → Wait for Running ✅

---

## Step 2: SSH into EC2 + Install Docker

```bash

sudo dnf update -y
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && unzip awscliv2.zip && sudo ./aws/install
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER
newgrp docker

# Fix PATH for Harness SSH deployments (non-interactive shell)
echo 'export PATH=/usr/bin:/usr/local/bin:$PATH' | sudo tee /etc/profile.d/harness-path.sh
sudo chmod +x /etc/profile.d/harness-path.sh

```

---

## Step 3: Install Docker Delegate (CD Level)

1. Harness UI: Account `yaswanth.arumulla` → Org `default` → Project `HarnessCICDZerotoHero`
2. Project Settings → **Delegates** → **+ New Delegate** → **Docker**
3. Name: `cd-docker-delegate`
4. Copy command → Modify → Run on EC2:

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

**NO `--network host`, NO tags, NO Runner!**

Wait 2 min → **Connected** ✅

---

## Step 3b: Create SSH Credential + Verify Connection

1. Project Settings → **Secrets** → **+ New Secret** → **SSH Credential**
2. **SSH Details:**
   - Name: `ec2-ssh-key`
   - Save and Continue
3. **Configuration:**
   - Auth Scheme: **SSH Key**
   - Authentication: **Username/SSH Key**
   - Username: `ec2-user`
   - Select or create SSH Key: Click **Create or Select a Secret** → **+ New Secret File**
     - Secret Name: `ec2-pem-key`
     - Secret Type: **File**
     - Upload: Select your `.pem` file
     - Save
   - Select `ec2-pem-key`
   - SSH Port: `22`
4. Click **Save and Continue**
5. Verify Connection:
   - Enter Host Name: Your EC2 public IP
   - Click **Test Connection** → ✅

---

## Step 4: Create Service in Harness UI

1. CD → **Services** → **+ New Service**
2. Name: `healthcare-website` (ID will auto-generate as `healthcarewebsite`)
3. Setup: **Inline**
4. Deployment Type: **Secure Shell**
5. Save

---

## Step 5: Create Environment in Harness UI

1. CD → **Environments** → **+ New Environment**
2. Name: `development`
3. Environment Type: **Pre-Production**
4. Setup: **Inline**
5. Save

---

## Step 5b: Create Infrastructure inside Environment

1. Inside `development` environment → **Infrastructure Definitions** tab
2. Click **+ Infrastructure Definition**
3. Name: `ec2-docker` (ID will auto-generate as `ec2docker`)
4. Deployment Type: **Secure Shell**
5. Setup: **Inline**
6. Infrastructure Type: **AWS**
7. Connector: Select `account.aws_account`
8. Region: Select your region
9. Host Filter: **Specify hosts** → Enter EC2 public IP
10. Credentials: Select `ec2-ssh-key` (created in Step 3b)
11. Save

---

## Step 6: Push Code to GitHub

```bash
git add .
git commit -m "Episode 6: Healthcare website CD"
git push origin master
```

---

## Step 7: Import Pipeline (in CD module)

1. CD → Pipelines → **+ Create a Pipeline** → **Import from Git**
2. Select: **Third-party Git provider**
3. Connector: `Github`
4. Repo: `Harness-CI-CD-Zero-to-Hero`
5. Branch: `master`
6. YAML Path: `Episode-06/Health care/.harness/pipeline-docker-cd.yaml`
7. Import

---

## Step 8: Run Pipeline

```
Stage 1: Build & Push to ECR ✅
Stage 2: Deploy to EC2 (CD stage) ✅
  ├── Deploy Container
  ├── Health Check (HTTP 200 on /health)
  ├── Tag :stable
  └── Rollback (auto on failure):
      ├── Stop Failed Deployment
      ├── Restore Last Successful Build
      ├── Start Previous Version
      └── Rollback Health Check
Stage 3: Approval ⏸️
Stage 4: Cleanup ✅
```

---

## Step 9: Access Website

```
http://EC2-PUBLIC-IP:5000
http://EC2-PUBLIC-IP:5000/health
http://EC2-PUBLIC-IP:5000/api/doctors
```

---

## Test Rollback

1. Run pipeline → success ✅ (`:stable` tagged)
2. Add `erxtcfgvhbjkmle` in `app.py` (between imports)
3. Push → Run pipeline
4. Stage 1 passes (image builds) ✅
5. Stage 2: Flask crashes → `/health` no response → Rollback triggers ✅

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| "No eligible delegates" | `docker ps` on EC2 |
| Website not loading | Security Group → allow port 5000 |
| "Service not found" | Create `healthcare-website` in Services UI |
| "Environment not found" | Create `development` in Environments UI |
| "Infrastructure not found" | Create `ec2-docker` inside development |
