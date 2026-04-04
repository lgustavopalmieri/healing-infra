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
9. [Deploy the Observability Stack](#9-deploy-the-observability-stack)
10. [Deploy the Application (K8s ServiceAccount)](#10-deploy-the-application-k8s-serviceaccount)
11. [Troubleshooting](#11-troubleshooting)
12. [Teardown (Destroy)](#12-teardown-destroy)

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
- The ability to create IAM roles, VPCs, EKS clusters, OpenSearch domains, RDS instances, RDS Proxies, Secrets Manager secrets, and SQS queues

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

# RDS PostgreSQL — scaled for load testing
rds_db_name             = "healing_specialist_db"
rds_username            = "healing_admin"
rds_password            = "YourStrongPassword123!"  # change this!
rds_engine_version      = "17"
rds_instance_class      = "db.t3.small"
rds_allocated_storage   = 20
rds_multi_az            = false
rds_skip_final_snapshot = true

# RDS Proxy — connection pooling for high-throughput workloads
rds_enable_proxy                       = true
rds_proxy_idle_client_timeout          = 1800
rds_proxy_require_tls                  = true
rds_proxy_max_connections_percent      = 100
rds_proxy_max_idle_connections_percent = 50
rds_proxy_connection_borrow_timeout    = 120
rds_proxy_debug_logging                = true

tags = {
  Team = "platform"
}
```

**Checklist before proceeding:**
- [ ] `github_org` is your real GitHub org/user
- [ ] `github_repos` lists the repo(s) that push images
- [ ] `rds_password` is a strong password (min 8 chars, mixed case, numbers)
- [ ] `rds_enable_proxy` is set to `true` if you want connection pooling via RDS Proxy
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
- ~12 resources from `module.rds_postgres` (subnet group, SG, instance + proxy, proxy SG, proxy target group, proxy target, Secrets Manager secret, IAM role/policy)
- ~5 resources from `module.sqs_healing_specialist` (IAM role, 2 policies, 2 attachments)
- ~4 resources from `module.opensearch` (optional SLR, SG, domain)

> **Note on RDS Proxy**: When `rds_enable_proxy = true`, the module creates ~7 additional resources (proxy, target group, target, security group, Secrets Manager secret + version, IAM role + policy). When `false`, only the base ~5 RDS resources are created.

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
aws rds describe-db-instances --query 'DBInstances[?DBInstanceIdentifier==`healing-dev-pg`].{Status:DBInstanceStatus,Engine:Engine,Class:DBInstanceClass}' --output table

echo ""
echo "=== RDS Proxy ==="
aws rds describe-db-proxies --query 'DBProxies[?DBProxyName==`healing-dev-pg-proxy`].{Status:Status,Endpoint:Endpoint,EngineFamily:EngineFamily}' --output table

echo ""
echo "=== IAM Pod Role ==="
aws iam get-role --role-name healing-dev-specialist-pod-role --query 'Role.Arn' --output text 2>/dev/null && echo "  Pod role: OK" || echo "  Pod role: MISSING"
```

**Everything healthy looks like:**
- EKS: Status = ACTIVE
- OpenSearch: Processing = False, Endpoint has a value
- RDS: Status = available
- RDS Proxy: Status = available, Endpoint has a value
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

## 9. Deploy the Observability Stack

Deploy the observability stack (OTel Collector, Prometheus, Grafana, kube-state-metrics) before deploying applications. This ensures the metrics pipeline is ready to receive data.

```bash
bash k8s/observability/apply.sh
```

The script deploys all components in order and waits for each to be ready. At the end it prints the Grafana URL.

**Verification:**
```bash
# Check all pods are running
kubectl get pods -n observability

# Get the Grafana URL
kubectl get ingress observability -n observability
```

Access Grafana at `http://<ALB_HOSTNAME>/grafana`. Default credentials: `admin` / see the `grafana-admin` Secret in the `observability` namespace.

> The observability ALB is separate from the application ALB (different `group.name`). Each has its own DNS hostname.

---

## 10. Deploy the Application (K8s ServiceAccount)

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

## 11. Troubleshooting

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

### "Error: creating RDS Proxy: DBProxyAlreadyExistsFault"

**Cause:** A proxy with the same name already exists (possibly from a failed previous apply).
**Fix:** Check and delete the orphaned proxy:
```bash
aws rds describe-db-proxies --query 'DBProxies[?contains(DBProxyName, `healing`)].{Name:DBProxyName,Status:Status}' --output table
aws rds delete-db-proxy --db-proxy-name healing-dev-pg-proxy
```
Wait for deletion, then re-run `terraform apply`.

### "Error: creating RDS Proxy: InvalidSubnet"

**Cause:** Not all Availability Zones support RDS Proxy. If some of the private subnets are in an unsupported AZ, the proxy creation may fail.
**Fix:** This is uncommon in `us-east-1` but can happen. Check the [AWS docs for supported AZs](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/rds-proxy.html) and adjust your `availability_zones` variable if needed.

### Application can't connect through the proxy (TLS errors)

**Cause:** `rds_proxy_require_tls = true` (default) requires the application to connect with SSL/TLS.
**Fix:** Either configure your application's database connection to use SSL, or set `rds_proxy_require_tls = false` in dev for testing.

### "context deadline exceeded" during EKS operations

**Cause:** The EKS cluster endpoint may not be reachable from your machine.
**Fix:** Make sure `cluster_endpoint_public_access = true` (default in dev). Run:
```bash
aws eks update-kubeconfig --region us-east-1 --name healing-dev
kubectl get nodes
```

---

## 12. Teardown (Destroy)

See the full destroy guide: **[dev-destroy-guide.md](dev-destroy-guide.md)**

The critical steps: **delete Kubernetes Ingress resources from all namespaces and destroy the observability stack before running `terraform destroy`**, otherwise the ALBs and Security Groups created by the Load Balancer Controller will be orphaned and block VPC deletion.

Quick version:

```bash
kubectl delete ingress --all -n healing
kubectl delete ingress --all -n observability
bash k8s/observability/destroy.sh
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
│  Step 7: Deploy observability stack                         │
│    bash k8s/observability/apply.sh                          │
├─────────────────────────────────────────────────────────────┤
│  Step 8: Create K8s ServiceAccount                          │
│    kubectl apply -f service-account.yaml                    │
├─────────────────────────────────────────────────────────────┤
│  Step 9: Deploy your application                            │
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
| RDS PostgreSQL db.t3.small (20 GiB) | 1 | ~$25/mo |
| RDS Proxy | 1 | ~$18/mo (billed per vCPU/h) |
| Secrets Manager secret (RDS credentials) | 1 | ~$0.40/mo |
| IAM Role (pod) + IAM Role (proxy) | 2 | free |
| IAM Policies (SQS + OpenSearch + Proxy) | 3 | free |
| Security Groups (OpenSearch + RDS + Proxy) | 3 | free |
| **Estimated total** | | **~$205/mo** |

> Costs are approximate US East (N. Virginia) pricing as of 2026. Actual costs vary by usage. The RDS Proxy cost is based on the number of vCPUs of the target RDS instance.

---

## Day-2 Operations

### Adding a new tenant/service

1. Add a new `module "sqs_<service>"` in `sqs.tf` with its own `opensearch_index_prefix`
2. `terraform apply`

The new pod role will have IAM-restricted access to only its index prefix.

### Scaling RDS

Edit `terraform.tfvars`:
```hcl
rds_instance_class    = "db.t3.medium"
rds_allocated_storage = 50
```
Then: `terraform apply`

> RDS instance class changes cause a brief downtime (~2-5 min). The RDS Proxy absorbs this by holding connections and replaying them after the instance is back — applications connected via the proxy see minimal disruption.

### Enabling / disabling the RDS Proxy

Edit `terraform.tfvars`:
```hcl
rds_enable_proxy = true   # or false to disable
```
Then: `terraform apply`

When enabled, applications should use the `rds_connection_endpoint` output as the database host — it automatically points to the proxy endpoint. When disabled, it falls back to the direct RDS address.

> **Proxy vs ALB on destroy**: Unlike the ALB (which is created outside Terraform by the Load Balancer Controller and requires manual cleanup before `terraform destroy`), the RDS Proxy is **fully managed by Terraform**. No manual deletion is needed — `terraform destroy` handles the correct teardown order automatically.

### Tuning RDS Proxy connection pool

Edit `terraform.tfvars`:
```hcl
rds_proxy_max_connections_percent      = 80   # cap pool to 80% of max_connections
rds_proxy_max_idle_connections_percent = 30   # keep fewer idle connections
rds_proxy_connection_borrow_timeout    = 60   # shorter wait before timeout
```
Then: `terraform apply`

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
