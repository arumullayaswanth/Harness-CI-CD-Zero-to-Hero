# 🚀 Episode 6, Topic 2 — Deploy GoCart to EKS (Kubernetes)

## Flow

```
Create EKS → Install K8s Delegate → Create Service + Environment → Import Pipeline → Run → LoadBalancer URL
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

## Step 1: Create EKS Cluster

1. GitHub → Actions → **"EKS Terraform"** → Run workflow → `action: apply`
2. Wait ~15 minutes
3. Output: Bastion IP + Cluster name

---

## Step 2: SSH into Bastion + Connect to EKS

```bash
aws ssm start-session --target INSTANCE-ID --region us-east-1
# OR
ssh -i harness-bastion-key.pem ec2-user@BASTION-IP

aws eks update-kubeconfig --region us-east-1 --name harness-eks-cluster
kubectl get nodes
```

---

## Step 3: Install Kubernetes Delegate

1. Harness UI → Project Settings → **Delegates** → **+ New Delegate** → **Kubernetes**
2. Name: `eks-k8s-delegate`
3. Download YAML → Apply on Bastion:

```bash
kubectl apply -f harness-delegate.yaml
kubectl get pods -n harness-delegate-ng
```

Wait 2 min → **Connected** ✅

---

## Step 4: Create Service in Harness UI

1. CD → **Services** → **+ New Service**
2. Name: `gocart`
3. Deployment Type: **Kubernetes**
4. **Manifests:**
   - Type: K8s Manifest
   - Store: GitHub
   - Connector: `account.Github`
   - Repo: `Harness-CI-CD-Zero-to-Hero`
   - Branch: `master`
   - Path: `Episode-06/gocart/k8s/`
5. **Artifacts:**
   - Type: Amazon ECR
   - Connector: `account.aws_account`
   - Region: (your region)
   - Image: `gocart`
   - Tag: `<+input>`
6. Save

---

## Step 5: Create Environment in Harness UI

1. CD → **Environments** → **+ New Environment** (or reuse `development`)
2. Name: `development`
3. Type: **Pre-Production**
4. Inside environment → **+ New Infrastructure**
5. Name: `eks-cluster` (ID will auto-generate as `ekscluster`)
6. Type: **Kubernetes**
7. Connector: **Inherit from Delegate** (select your `eks-k8s-delegate`)
8. Namespace: `gocart`
9. Save

---

## Step 6: Push Code to GitHub

```bash
git add .
git commit -m "Episode 6: GoCart K8s CD"
git push origin master
```

---

## Step 7: Import Pipeline (in CD module)

1. CD → Pipelines → **+ Create a Pipeline** → **Import from Git**
2. Select: **Third-party Git provider**
3. Connector: `Github`
4. Repo: `Harness-CI-CD-Zero-to-Hero`
5. Branch: `master`
6. YAML Path: `Episode-06/gocart/.harness/pipeline-k8s-cd.yaml`
7. Import

---

## Step 8: Run Pipeline

```
Stage 1: Build & Push to ECR ✅
Stage 2: Deploy to EKS (CD Deployment stage) ✅
  ├── K8sRollingDeploy (Harness native — applies all K8s manifests)
  ├── Verify Deployment (pods + LoadBalancer)
  ├── Health Check (HTTP 200)
  └── Rollback (auto on failure):
      └── K8sRollingRollback (reverts to previous revision)
Stage 3: Approval ⏸️
Stage 4: Cleanup ✅
```

---

## Step 9: Access GoCart

From Stage 2 logs, get LoadBalancer URL:
```
http://LOADBALANCER-URL
```

Open in browser → GoCart E-Commerce UI ✅

---

## Test Rollback

1. Run pipeline → success ✅
2. Break `k8s/deployment.yaml` (add `dfghjk: invalid`)
3. Push → Run pipeline
4. Stage 1 passes ✅
5. Stage 2: `K8sRollingDeploy` fails → **K8sRollingRollback** auto-triggers ✅

---

## Verify from Bastion

```bash
kubectl get pods -n gocart
kubectl get svc -n gocart
kubectl rollout history deployment/gocart -n gocart
```

---

## Cleanup

```bash
# Pipeline does this after approval
# Or manually:
kubectl delete namespace gocart
aws ecr delete-repository --repository-name gocart --force --region us-east-1

# Destroy EKS (stop billing!):
# GitHub → Actions → "EKS Terraform" → destroy → confirm_destroy: yes
```

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| "No eligible delegates" | `kubectl get pods -n harness-delegate-ng` |
| "Service not found" | Create `gocart` in Services UI |
| "Environment not found" | Create `development` in Environments UI |
| "Infrastructure not found" | Create `eks-cluster` inside development |
| Pods `ImagePullBackOff` | ECR image missing — check Stage 1 |
| Pods `CrashLoopBackOff` | `kubectl logs deployment/gocart -n gocart` |
| No LoadBalancer URL | Wait 2-3 min |
