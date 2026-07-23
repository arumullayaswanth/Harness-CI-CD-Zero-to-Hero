#!/bin/bash
# ═══════════════════════════════════════════════════════════════════
# tools.sh — Bastion Server Setup Script
# Installs: kubectl, eksctl, Helm, AWS CLI, Docker, SonarQube
# OS: Amazon Linux 2023
# Run on first boot via user_data
# ═══════════════════════════════════════════════════════════════════

echo "=========================================="
echo "  BASTION SERVER SETUP"
echo "=========================================="

# Update system
dnf update -y
dnf install -y unzip jq bc git

# Don't install curl if curl-minimal exists (Amazon Linux 2023)
command -v curl >/dev/null 2>&1 || dnf install -y curl-minimal

# ─────────────────────────────────────────────────────────────────
# SSM Agent (pre-installed on AL2023)
# ─────────────────────────────────────────────────────────────────
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent

# ─────────────────────────────────────────────────────────────────
# Docker
# ─────────────────────────────────────────────────────────────────
dnf install -y docker
systemctl enable docker
systemctl start docker
usermod -aG docker ec2-user
chmod 666 /var/run/docker.sock

# ─────────────────────────────────────────────────────────────────
# kubectl
# ─────────────────────────────────────────────────────────────────
curl -LO "https://dl.k8s.io/release/$(curl -fsSL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
mv kubectl /usr/local/bin/
kubectl version --client || true

# ─────────────────────────────────────────────────────────────────
# eksctl
# ─────────────────────────────────────────────────────────────────
curl --silent --location \
  "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" \
  | tar xz -C /tmp
mv /tmp/eksctl /usr/local/bin/
eksctl version || true

# ─────────────────────────────────────────────────────────────────
# Helm
# ─────────────────────────────────────────────────────────────────
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
helm version || true

# ─────────────────────────────────────────────────────────────────
# Kernel params for SonarQube (Elasticsearch requirement)
# ─────────────────────────────────────────────────────────────────
tee /etc/sysctl.d/99-sonarqube.conf > /dev/null <<'EOF'
vm.max_map_count=524288
fs.file-max=131072
EOF
sysctl --system

# ─────────────────────────────────────────────────────────────────
# SonarQube (Docker, port 9000)
# Access: http://BASTION-IP:9000  Login: admin / admin
# ─────────────────────────────────────────────────────────────────
docker volume create sonarqube_data
docker volume create sonarqube_logs
docker volume create sonarqube_extensions

docker rm -f sonarqube >/dev/null 2>&1 || true
docker run -d \
  --name sonarqube \
  --restart unless-stopped \
  -p 9000:9000 \
  -v sonarqube_data:/opt/sonarqube/data \
  -v sonarqube_logs:/opt/sonarqube/logs \
  -v sonarqube_extensions:/opt/sonarqube/extensions \
  sonarqube:lts-community

# ─────────────────────────────────────────────────────────────────
# Helm Repos
# ─────────────────────────────────────────────────────────────────
helm repo add stable https://charts.helm.sh/stable || true
helm repo add bitnami https://charts.bitnami.com/bitnami || true
helm repo update || true

echo "=========================================="
echo "  ✅ BASTION SETUP COMPLETE!"
echo "=========================================="
echo ""
echo "  Connect to EKS:"
echo "    aws eks update-kubeconfig --name harness-eks-cluster --region us-east-1"
echo "    kubectl get nodes"
echo ""
echo "  SonarQube: http://BASTION-IP:9000 (admin/admin)"
echo ""
