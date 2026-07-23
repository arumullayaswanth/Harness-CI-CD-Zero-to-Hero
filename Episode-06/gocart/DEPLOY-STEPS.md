# 🚀 Episode 6, Topic 2 — Deploy GoCart to EKS (Kubernetes)

## Flow

```
GitHub Actions (create EKS) → Bastion → Install K8s Delegate → Run Pipeline → LoadBalancer URL
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

1. GitHub → Actions → **"EKS Terraform"** workflow
2. Run workflow → `action: apply`
3. Wait ~15 minutes

Output:
```
EKS Cluster: harness-eks-cluster
Bastion IP: 54.xxx.xxx.xxx
```

---

## Step 2: SSH into Bastion

```bash
ssh -i harness-bastion-key.pem ubuntu@BASTION-IP
```

---

## Step 3: Connect to EKS

```bash
aws eks update-kubeconfig --region us-east-1 --name harness-eks-cluster
kubectl get nodes
```

---

## Step 4: Install Kubernetes Delegate

1. Harness → Project Settings → Delegates → + New Delegate → **Kubernetes**
2. Name: `eks-k8s-delegate`
3. Download YAML
4. On Bastion:

```bash
kubectl apply -f harness-delegate.yaml
kubectl get pods -n harness-delegate-ng
```

Wait 2 min → Harness UI → **Connected** ✅

---

## Step 5: Push Code to GitHub

```bash
git add .
git commit -m "Episode 6: GoCart K8s CD"
git push origin master
```

---

## Step 6: Import Pipeline

1. Pipelines → Import from Git
2. Pipeline Name: `episode6-gocart-k8s-cd`
3. Connector: `Github`
4. Repo: `Harness-CI-CD-Zero-to-Hero`
5. Branch: `master`
6. YAML Path: `Episode-06/gocart/.harness/pipeline-k8s-cd.yaml`
7. Import

---

## Step 7: Run Pipeline

1. Run Pipeline → Branch: `master`
2. Watch:

```
Stage 1: Build & Push to ECR ✅
Stage 2: Deploy to Kubernetes ✅
  ├── Apply namespace, configmap, secret, postgres
  ├── Wait for postgres ready
  ├── Apply deployment + service
  ├── Verify rollout
  └── Health Check (HTTP 200)
Stage 3: Approval ⏸️
Stage 4: Cleanup ✅
```

---

## Step 8: Access GoCart

From Stage 2 logs, copy LoadBalancer URL:
```
http://LOADBALANCER-URL
```

Open in browser → GoCart E-Commerce UI visible ✅

---

## Test Rollback

1. Break `k8s/deployment.yaml` (add invalid field)
2. Push → Run pipeline
3. Stage 1 passes (image builds fine — code is correct)
4. Stage 2 → `kubectl apply` fails or Health Check fails
5. **Rollback triggers**: `kubectl rollout undo` → previous version restored ✅

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
| Pods `CrashLoopBackOff` | `kubectl logs deployment/gocart -n gocart` |
| Pods `CreateContainerConfigError` | ConfigMap/Secret not applied — check deploy order |
| "ImagePullBackOff" | ECR image missing — run Stage 1 first |
| No LoadBalancer URL | Wait 2-3 min (ELB provisioning) |
| Postgres not ready | `kubectl get pods -l app=postgres -n gocart` |

---

## Cost

- EKS: ~$3.73/day
- **Destroy when done!**
