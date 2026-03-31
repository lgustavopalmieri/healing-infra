# Dev Environment — Deployment Guide

Step-by-step guide to provision the `dev` environment from zero. Follow every step in order. Each step has a **verification** command so you know it worked before moving on.

---

## Table of Contents

1. [Prerequisites](#1-prerequisites)
2. [AWS Credentials](#2-aws-credentials)
3. [Bootstrap (State Backend)](#3-bootstrap-state-backend)
4. [Prepare the tfvars](#4-prepare-the-tfvars)
5. [Initialize Terraform](#5-initialize-terraform)
6. [Apply — Single Command](#6-apply--single-command)
7. [Post-Deploy Verification](#7-post-deploy-verification)
8. [Configure kubectl](#8-configure-kubectl)
9. [Deploy the Application (K8s ServiceAccount)](#9-deploy-the-application-k8s-serviceaccount)
10. [Troubleshooting](#10-troubleshooting)
11. [Teardown (Destroy)](#11-teardown-destroy)

---

## 1. Prerequisites

Install these tools before starting:

| Tool | Minimum Version | Check Command |
|---|---|---|
| Terraform | >= 1.5 | `terraform version` |
| AWS CLI | v2 | `aws --version` |
| kubectl | >= 1.28 | `kubectl version --client` |
| Git | any | `git --version` |

**AWS Account requirements:**
- An AWS account with admin or power-user access
- The ability to create IAM roles, VPCs, EKS clusters, OpenSearch domains, RDS instances, and SQS queues

---

## 2. AWS Credentials

Configure your credentials. Terraform and AWS CLI must use the same identity.

**Option A — Named profile (recommended):**
```bash
export AWS_PROFILE=your-dev-profile
aws sts get-caller-identity
```

**Option B — Environment variables:**
```bash
export AWS_ACCESS_KEY_ID="AKIA..."
export AWS_SECRET_ACCESS_KEY="..."
export AWS_DEFAULT_REGION="us-east-1"
aws sts get-caller-identity
```

**Verification:**
```bash
aws sts get-caller-identity
# Must return your Account ID, ARN, and UserId without errors
```

---

## 3. Bootstrap (State Backend)

The bootstrap creates the S3 bucket and DynamoDB table that store Terraform state. This only needs to run **once per environment**.

```bash
cd terraform/bootstrap/dev
```

**3.1 Create the tfvars:**
```bash
cp dev.tfvars.example dev.tfvars
```

Edit `dev.tfvars`:
```hcl
project_name  = "healing"
environment   = "dev"
aws_region    = "us-east-1"
force_destroy = true
tags = {
  Team = "platform"
}
```

**3.2 Init and apply:**
```bash
terraform init
terraform apply -var-file=dev.tfvars
```

Type `yes` when prompted.

**3.3 Verify and note the outputs:**
```bash
terraform output
```

Expected output:
```
aws_region        = "us-east-1"
lock_table_name   = "healing-dev-dev-terraform-locks"
state_bucket_name = "healing-dev-dev-terraform-state"
```

**3.4 Confirm the backend block matches:**

Open `terraform/environments/dev/main.tf` and verify the `backend "s3"` block matches the bootstrap outputs. If your `project_name` or `environment` values differ from `healing`/`dev`, update the backend block with your actual output values.

```bash
cd ../../..
```

---

## 4. Prepare the tfvars

```bash
cd terraform/environments/dev
cp dev.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` — replace **every** `REPLACE-*` placeholder:

```hcl
project_name = "healing"
environment  = "dev"
cluster_name = "healing-dev"
aws_region   = "us-east-1"

# Networking
vpc_cidr           = "10.0.0.0/16"
single_nat_gateway = true

# EKS
kubernetes_version  = "1.35"
node_instance_types = ["t3.medium"]
node_min_size       = 1
node_max_size       = 3
node_desired_size   = 1

# ECR
ecr_repository_name = "healing-specialist"
ecr_force_delete    = true

# GitHub OIDC — replace with your values
github_org   = "your-github-org"
github_repos = ["healing-specialist"]

# OpenSearch — lightweight dev config
opensearch_engine_version             = "OpenSearch_2.17"
opensearch_instance_type              = "t3.small.search"
opensearch_instance_count             = 1
opensearch_ebs_volume_size            = 20
opensearch_zone_awareness_enabled     = false
opensearch_dedicated_master_enabled   = false
opensearch_create_service_linked_role = false

# SQS / Workload Identity
sqs_healing_k8s_namespace       = "healing"
sqs_healing_k8s_service_account = "healing-specialist"
sqs_healing_queue_prefix        = "specialist"

# RDS PostgreSQL
rds_db_name             = "healing_specialist_db"
rds_username            = "healing_admin"
rds_password            = "YourStrongPassword123!"  # change this!
rds_engine_version      = "17"
rds_instance_class      = "db.t3.micro"
rds_allocated_storage   = 10
rds_multi_az            = false
rds_skip_final_snapshot = true

tags = {
  Team = "platform"
}
```

**Checklist before proceeding:**
- [ ] `github_org` is your real GitHub org/user
- [ ] `github_repos` lists the repo(s) that push images
- [ ] `rds_password` is a strong password (min 8 chars, mixed case, numbers)
- [ ] `opensearch_create_service_linked_role` is correct (see below)
- [ ] No `REPLACE-*` placeholders remain

> **How to check if the SLR already exists:**
> ```bash
> aws iam get-role --role-name AWSServiceRoleForAmazonOpenSearchService 2>/dev/null && echo "EXISTS — keep false" || echo "DOES NOT EXIST — set to true"
> ```
> The Service-Linked Role is **per AWS account** (not per environment). If you've ever created an OpenSearch domain in this account (even manually), it already exists. **Default is `false`** — only set to `true` if the command above says "DOES NOT EXIST".

---

## 5. Initialize Terraform

```bash
terraform init
```

**Expected output (last lines):**
```
Terraform has been successfully initialized!
```

If you see errors about the S3 backend:
- Verify your bootstrap ran successfully (step 3)
- Verify the backend block in `main.tf` matches the bootstrap outputs
- Verify your AWS credentials have access to the S3 bucket

---

## 6. Apply — Single Command

Everything is deployed in a single `terraform apply`. No phases, no targets.

**6.1 Plan:**
```bash
terraform plan
```

Review the plan. You should see approximately:
- ~20 resources from `module.eks` (VPC, subnets, NAT, EKS cluster, node group, ECR, IAM roles...)
- ~5 resources from `module.rds_postgres` (subnet group, SG, instance)
- ~5 resources from `module.sqs_healing_specialist` (IAM role, 2 policies, 2 attachments)
- ~4 resources from `module.opensearch` (optional SLR, SG, domain)

**6.2 Apply:**
```bash
terraform apply
```

Type `yes` when prompted.

> **Timing**: This step takes **20-35 minutes**. The EKS cluster takes ~10 min and the OpenSearch domain takes ~15-20 min. Both are created in parallel. Do not interrupt — let it finish.

**6.3 Verify — get all outputs as JSON:**
```bash
terraform output -json
```

---

## 7. Post-Deploy Verification

Run all verifications to confirm the environment is healthy:

```bash
echo "=== EKS Cluster ==="
aws eks describe-cluster --name healing-dev --query 'cluster.{Status:status,Endpoint:endpoint,Version:version}' --output table

echo ""
echo "=== OpenSearch Domain ==="
aws opensearch describe-domain --domain-name healing-dev --query 'DomainStatus.{Endpoint:Endpoint,EngineVersion:EngineVersion,Processing:Processing,InstanceType:ClusterConfig.InstanceType}' --output table

echo ""
echo "=== RDS Instance ==="
aws rds describe-db-instances --query 'DBInstances[?DBInstanceIdentifier==`healing-dev-db`].{Status:DBInstanceStatus,Engine:Engine,Class:DBInstanceClass}' --output table

echo ""
echo "=== IAM Pod Role ==="
aws iam get-role --role-name healing-dev-specialist-pod-role --query 'Role.Arn' --output text 2>/dev/null && echo "  Pod role: OK" || echo "  Pod role: MISSING"
```

**Everything healthy looks like:**
- EKS: Status = ACTIVE
- OpenSearch: Processing = False, Endpoint has a value
- RDS: Status = available
- IAM role: OK

---

## 8. Configure kubectl

```bash
aws eks update-kubeconfig --region us-east-1 --name healing-dev

# Verify
kubectl get nodes
kubectl cluster-info
```

You should see your node(s) in `Ready` state.

---

## 9. Deploy the Application (K8s ServiceAccount)

The IRSA role is ready. Now create the Kubernetes ServiceAccount that links to it:

```bash
# Get the role ARN
POD_ROLE_ARN=$(aws iam get-role --role-name healing-dev-specialist-pod-role --query 'Role.Arn' --output text)

# Create namespace (if it doesn't exist)
kubectl create namespace healing --dry-run=client -o yaml | kubectl apply -f -

# Create ServiceAccount with IRSA annotation
kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: healing-specialist
  namespace: healing
  annotations:
    eks.amazonaws.com/role-arn: ${POD_ROLE_ARN}
EOF

# Verify
kubectl get sa healing-specialist -n healing -o yaml
```

The annotation `eks.amazonaws.com/role-arn` is what makes IRSA work. Any pod using this ServiceAccount will automatically receive temporary AWS credentials for the `healing-dev-specialist-pod-role` IAM role.

**What the pod can do:**
- **SQS**: Create/manage/send/receive queues matching `specialist-*`
- **OpenSearch**: HTTP access restricted to `healing-*` indices only (IAM ARN restriction)
- **Cluster-level**: Read-only cluster health, `_cat`, `_cluster/health`

---

## 10. Troubleshooting

### "Error: creating OpenSearch Service Linked Role: already exists"

**Cause:** The `AWSServiceRoleForAmazonOpenSearchService` SLR already exists in your account.
**Fix:** In your `terraform.tfvars`, set:
```hcl
opensearch_create_service_linked_role = false
```
Then re-run the apply.

### "Error: creating OpenSearch Domain: ValidationException"

**Cause:** The engine version might not be available in your region, or the instance type is not supported.
**Fix:** Check available versions and instance types:
```bash
aws opensearch list-versions --query 'Versions' --output table
aws opensearch list-instance-type-details --engine-version OpenSearch_2.17 --query 'InstanceTypeDetails[].InstanceType' --output table
```
Update `opensearch_engine_version` or `opensearch_instance_type` in your tfvars accordingly.

### OpenSearch domain stuck in "Processing"

**Cause:** Domain creation takes 15-20 minutes. If it exceeds 30 minutes, check:
```bash
aws opensearch describe-domain --domain-name healing-dev --query 'DomainStatus.{Processing:Processing,ChangeProgressDetails:ChangeProgressDetails}'
```
Wait for it to complete.

### "context deadline exceeded" during EKS operations

**Cause:** The EKS cluster endpoint may not be reachable from your machine.
**Fix:** Make sure `cluster_endpoint_public_access = true` (default in dev). Run:
```bash
aws eks update-kubeconfig --region us-east-1 --name healing-dev
kubectl get nodes
```

---

## 11. Teardown (Destroy)

See the full destroy guide: **[dev-destroy-guide.md](dev-destroy-guide.md)**

The critical step: **delete Kubernetes Ingress resources before running `terraform destroy`**, otherwise the ALB and Security Groups created by the Load Balancer Controller will be orphaned and block VPC deletion.

Quick version:

```bash
kubectl delete ingress --all -n healing
sleep 60
cd terraform/environments/dev
terraform destroy
```

---

## Quick Reference — Complete Flow

```
┌─────────────────────────────────────────────────────────────┐
│  Step 1: AWS Credentials                                    │
│    export AWS_PROFILE=dev                                   │
│    aws sts get-caller-identity                              │
├─────────────────────────────────────────────────────────────┤
│  Step 2: Bootstrap (once)                                   │
│    cd terraform/bootstrap/dev                               │
│    terraform init && terraform apply -var-file=dev.tfvars   │
├─────────────────────────────────────────────────────────────┤
│  Step 3: Environment tfvars                                 │
│    cd terraform/environments/dev                            │
│    cp dev.tfvars.example terraform.tfvars                   │
│    # Edit terraform.tfvars                                  │
├─────────────────────────────────────────────────────────────┤
│  Step 4: Init                                               │
│    terraform init                                           │
├─────────────────────────────────────────────────────────────┤
│  Step 5: Apply (~25 min)                                    │
│    terraform apply                                          │
├─────────────────────────────────────────────────────────────┤
│  Step 6: Configure kubectl                                  │
│    aws eks update-kubeconfig --name healing-dev             │
├─────────────────────────────────────────────────────────────┤
│  Step 7: Create K8s ServiceAccount                          │
│    kubectl apply -f service-account.yaml                    │
├─────────────────────────────────────────────────────────────┤
│  Step 8: Deploy your application                            │
│    # Your app deployment with serviceAccountName set        │
└─────────────────────────────────────────────────────────────┘
```

---

## What Gets Created (Resource Inventory)

| Resource | Count | Approx. Cost (dev) |
|---|---|---|
| VPC + 3 private + 3 public subnets + 1 NAT | 1 | ~$32/mo (NAT) |
| EKS Cluster + 1 t3.medium node | 1 | ~$73/mo (EKS) + ~$30/mo (EC2) |
| ECR Repository | 1 | free tier |
| OpenSearch t3.small.search (1 node, 20 GiB) | 1 | ~$26/mo |
| RDS PostgreSQL db.t3.micro (10 GiB) | 1 | ~$13/mo (or free tier) |
| IAM Role (pod) | 1 | free |
| IAM Policies (SQS + OpenSearch) | 2 | free |
| Security Groups (OpenSearch + RDS) | 2 | free |
| **Estimated total** | | **~$175/mo** |

> Costs are approximate US East (N. Virginia) pricing as of 2026. Actual costs vary by usage.

---

## Day-2 Operations

### Adding a new tenant/service

1. Add a new `module "sqs_<service>"` in `sqs.tf` with its own `opensearch_index_prefix`
2. `terraform apply`

The new pod role will have IAM-restricted access to only its index prefix.

### Scaling OpenSearch

Edit `terraform.tfvars`:
```hcl
opensearch_instance_type  = "t3.medium.search"
opensearch_instance_count = 2
opensearch_ebs_volume_size = 50
```
Then: `terraform apply`

### Updating OpenSearch engine version

Edit `terraform.tfvars`:
```hcl
opensearch_engine_version = "OpenSearch_2.19"
```
Then: `terraform apply`

> OpenSearch blue/green upgrades can take 15-30 minutes. Plan accordingly.

---

## Architecture — How Index Isolation Works

Since the OpenSearch domain is VPC-only (no public endpoint), security is layered:

1. **Network layer**: VPC Security Group allows only traffic from within the VPC CIDR on port 443
2. **IAM layer**: The domain access policy allows `es:ESHttp*` from any principal, but each pod's IAM role restricts access to specific index patterns via ARN:
   - `arn:aws:es:us-east-1:ACCOUNT:domain/healing-dev/healing-*` — only `healing-*` indices
3. **SQS layer**: Each pod can only create/use queues matching its prefix (`specialist-*`)

This means: even if two services run in the same VPC, service A cannot access service B's indices because its IAM policy doesn't include service B's index prefix in the Resource ARN.
