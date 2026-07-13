# SonarQube on EC2 — Setup Steps

## Step 1: Create EC2 Instance

1. AWS Console → EC2 → Launch Instance
2. Settings:
   - Name: `sonarqube-server`
   - OS: Amazon Linux 2023
   - Instance type: `t3.medium` (minimum 4 GB RAM)
   - Key pair: Create or select one
   - Security Group: Allow port **22** (SSH) and **9000** (SonarQube)
3. Launch Instance

---

## Step 2: Connect to EC2

```bash
ssh -i "your-key.pem" ec2-user@YOUR-EC2-PUBLIC-IP
```

---

## Step 3: Install Docker and Run SonarQube

```bash
# Switch to root user
sudo -i

# Update system packages
dnf update -y

# Install Docker
dnf install -y docker

# Start Docker service
systemctl start docker

# Enable Docker to start on boot
systemctl enable docker

# Verify Docker is running
docker --version
systemctl status docker
```

Now run SonarQube:

```bash
# Pull and run SonarQube container
docker run -d \
  --name sonarqube \
  -p 9000:9000 \
  sonarqube:lts-community

# Check if container is running
docker ps

# Wait 1-2 minutes, then check logs
docker logs sonarqube | tail -5
```

When you see `SonarQube is operational` in logs → it's ready.

Verify from EC2 itself:
```bash
curl http://localhost:9000
```

If you get HTML response → SonarQube is running ✅

---

## Step 4: Access SonarQube

Open browser: `http://YOUR-EC2-PUBLIC-IP:9000`

---

## Step 5: Login

- Username: `admin`
- Password: `admin`
- It asks to change password → set a new one

---

## Step 6: Generate Token

1. Click avatar (top-right) → My Account
2. Click **Security** tab
3. Token Name: `harness-pipeline`
4. Click **Generate**
5. Copy the token (shown only once)

---

## Step 7: Add to Harness

**Secret:**
- Project Settings → Secrets → + New Secret → Text
- Name: `sonar_token`
- Value: paste token

**Variable:**
- Project Settings → Variables → + New Variable
- Name: `sonar_host_url`
- Value: `http://YOUR-EC2-PUBLIC-IP:9000`

---

## Done ✅

Pipeline will send code to SonarQube and results appear on the dashboard.
