# Dev Environment — Destroy Guide

Step-by-step guide to completely destroy the `dev` environment without orphaned resources. Follow every step in order.

---

## Prerequisites

- AWS CLI v2 configured (`aws sts get-caller-identity` works)
- kubectl configured for the cluster (`kubectl get nodes` works)
- Terraform initialized in `terraform/environments/dev`

---

## Step 1 — Delete Kubernetes Ingress resources

The AWS Load Balancer Controller creates ALBs, Target Groups, and Security Groups **outside of Terraform**. If you skip this step, those resources will be orphaned and block the VPC deletion.

```bash
kubectl delete ingress --all -n healing
```

Verify the ALB is being deprovisioned:

```bash
aws elbv2 describe-load-balancers \
  --query 'LoadBalancers[?contains(LoadBalancerName, `healing`)].{Name:LoadBalancerName,State:State.Code}' \
  --output table
```

Wait until the table is empty (ALB fully deleted). This takes ~30-60 seconds.

```bash
echo "Waiting 60s for ALB cleanup..."
sleep 60
```

Verify it's gone:

```bash
aws elbv2 describe-load-balancers \
  --query 'LoadBalancers[?contains(LoadBalancerName, `healing`)].LoadBalancerName' \
  --output text
```

Expected: empty output (no ALBs remaining).

---

## Step 2 — Delete remaining Kubernetes workloads

Delete all workloads so the controller has time to clean up any remaining cloud resources (NLBs, target groups, etc.) before the cluster goes away.

```bash
kubectl delete all --all -n healing
kubectl delete sa --all -n healing
kubectl delete namespace healing
```

Wait a few seconds for cleanup:

```bash
sleep 10
```

---

## Step 3 — Terraform destroy

```bash
cd terraform/environments/dev
terraform destroy
```

Type `yes` when prompted. This takes ~15-25 minutes.

> **RDS Proxy — no manual action needed.** Unlike the ALB (created outside Terraform by the Kubernetes Load Balancer Controller), the RDS Proxy, its target group, Secrets Manager secret, and IAM role are all **fully managed by Terraform**. The destroy command handles the correct teardown order automatically:
>
> `proxy target → target group → proxy → security group → secrets → IAM role → RDS instance`
>
> You do **not** need to delete the proxy manually before running `terraform destroy`.

---

## Step 4 — Delete SQS queues

The application creates SQS FIFO queues at runtime (not managed by Terraform). Delete all queues with the `specialist-` prefix:

```bash
aws sqs list-queues --queue-name-prefix specialist- --query 'QueueUrls[]' --output text \
  | tr '\t' '\n' \
  | while read -r URL; do
      echo "Deleting $URL..."
      aws sqs delete-queue --queue-url "$URL"
    done
```

Verify they're gone:

```bash
aws sqs list-queues --queue-name-prefix specialist- --output text
```

Expected: empty output.

---

## Step 5 — Verify no orphaned resources

After destroy completes, verify nothing was left behind:

```bash
# Check for orphaned ALBs
echo "=== Orphaned ALBs ==="
aws elbv2 describe-load-balancers \
  --query 'LoadBalancers[?contains(LoadBalancerName, `healing`) || contains(LoadBalancerName, `k8s-`)].{Name:LoadBalancerName,VPC:VpcId}' \
  --output table

# Check for orphaned Target Groups
echo ""
echo "=== Orphaned Target Groups ==="
aws elbv2 describe-target-groups \
  --query 'TargetGroups[?contains(TargetGroupName, `k8s-healing`)].{Name:TargetGroupName,ARN:TargetGroupArn}' \
  --output table

# Check for orphaned Security Groups (k8s- prefix)
echo ""
echo "=== Orphaned Security Groups ==="
aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=k8s-*" \
  --query 'SecurityGroups[].{ID:GroupId,Name:GroupName,VPC:VpcId}' \
  --output table

# Check for orphaned EIPs
echo ""
echo "=== Unattached Elastic IPs ==="
aws ec2 describe-addresses \
  --query 'Addresses[?AssociationId==null].{AllocationId:AllocationId,PublicIp:PublicIp}' \
  --output table

# Check for orphaned RDS Proxies
echo ""
echo "=== Orphaned RDS Proxies ==="
aws rds describe-db-proxies \
  --query 'DBProxies[?contains(DBProxyName, `healing`)].{Name:DBProxyName,Status:Status}' \
  --output table

# Check for orphaned Secrets Manager secrets (RDS credentials)
echo ""
echo "=== Orphaned Secrets (RDS credentials) ==="
aws secretsmanager list-secrets \
  --filters Key=name,Values=healing-dev-rds-creds \
  --query 'SecretList[].{Name:Name,DeletedDate:DeletedDate}' \
  --output table
```

**Expected**: All sections should show empty tables. If anything shows up, proceed to Step 6.

---

## Step 6 — Clean up orphaned resources (only if Step 5 found something)

If Step 4 found orphaned resources, run these commands to clean them up. Skip any section that was already clean.

### 6.1 — Delete orphaned ALBs

```bash
# List and delete each ALB
for ARN in $(aws elbv2 describe-load-balancers --query 'LoadBalancers[?contains(LoadBalancerName, `k8s-`)].LoadBalancerArn' --output text); do
  echo "Deleting listeners for $ARN..."
  for LISTENER in $(aws elbv2 describe-listeners --load-balancer-arn "$ARN" --query 'Listeners[].ListenerArn' --output text); do
    aws elbv2 delete-listener --listener-arn "$LISTENER"
  done
  echo "Deleting ALB $ARN..."
  aws elbv2 delete-load-balancer --load-balancer-arn "$ARN"
done

echo "Waiting 60s for ENIs to release..."
sleep 60
```

### 6.2 — Delete orphaned Target Groups

```bash
for ARN in $(aws elbv2 describe-target-groups --query 'TargetGroups[?contains(TargetGroupName, `k8s-healing`)].TargetGroupArn' --output text); do
  echo "Deleting target group $ARN..."
  aws elbv2 delete-target-group --target-group-arn "$ARN"
done
```

### 6.3 — Delete orphaned Security Groups

```bash
for SG in $(aws ec2 describe-security-groups --filters "Name=group-name,Values=k8s-*" --query 'SecurityGroups[].GroupId' --output text); do
  echo "Deleting security group $SG..."
  aws ec2 delete-security-group --group-id "$SG"
done
```

### 6.4 — Delete orphaned RDS Proxies

```bash
for PROXY in $(aws rds describe-db-proxies --query 'DBProxies[?contains(DBProxyName, `healing`)].DBProxyName' --output text); do
  echo "Deregistering targets for $PROXY..."
  for TGT in $(aws rds describe-db-proxy-targets --db-proxy-name "$PROXY" --query 'Targets[].RdsResourceId' --output text 2>/dev/null); do
    aws rds deregister-db-proxy-targets --db-proxy-name "$PROXY" --db-instance-identifiers "$TGT" 2>/dev/null
  done
  echo "Deleting proxy $PROXY..."
  aws rds delete-db-proxy --db-proxy-name "$PROXY"
done

echo "Waiting 30s for proxy cleanup..."
sleep 30
```

### 6.5 — Delete orphaned Secrets Manager secrets

```bash
for SECRET_ARN in $(aws secretsmanager list-secrets --filters Key=name,Values=healing-dev-rds-creds --query 'SecretList[].ARN' --output text); do
  echo "Deleting secret $SECRET_ARN..."
  aws secretsmanager delete-secret --secret-id "$SECRET_ARN" --force-delete-without-recovery
done
```

### 6.6 — Release orphaned Elastic IPs

```bash
for ALLOC in $(aws ec2 describe-addresses --query 'Addresses[?AssociationId==null].AllocationId' --output text); do
  echo "Releasing EIP $ALLOC..."
  aws ec2 release-address --allocation-id "$ALLOC"
done
```

### 6.7 — Re-run terraform destroy

If orphaned resources were blocking the VPC:

```bash
cd terraform/environments/dev
terraform destroy
```

---

## Step 7 — Destroy the state backend (optional)

Only do this if you will never need the state again.

```bash
cd terraform/bootstrap/dev
terraform destroy -var-file=dev.tfvars
```

---

## Quick Reference — Complete Destroy Flow

```
┌──────────────────────────────────────────────────────────────┐
│  Step 1: Delete Kubernetes Ingress                           │
│    kubectl delete ingress --all -n healing                   │
│    sleep 60                                                  │
├──────────────────────────────────────────────────────────────┤
│  Step 2: Delete remaining workloads                          │
│    kubectl delete all --all -n healing                       │
│    kubectl delete namespace healing                          │
├──────────────────────────────────────────────────────────────┤
│  Step 3: Terraform destroy (~15-25 min)                      │
│    cd terraform/environments/dev                             │
│    terraform destroy                                         │
│    (RDS Proxy is destroyed automatically — no manual action) │
├──────────────────────────────────────────────────────────────┤
│  Step 4: Delete SQS queues (app-created, not in Terraform)   │
│    aws sqs list-queues --queue-name-prefix specialist- ...   │
├──────────────────────────────────────────────────────────────┤
│  Step 5: Verify — check for orphaned ALBs, SGs, EIPs,       │
│          RDS Proxies, Secrets Manager secrets                 │
├──────────────────────────────────────────────────────────────┤
│  Step 6: Clean up orphans (only if Step 5 found something)   │
├──────────────────────────────────────────────────────────────┤
│  Step 7: Destroy bootstrap (optional)                        │
│    cd terraform/bootstrap/dev                                │
│    terraform destroy -var-file=dev.tfvars                    │
└──────────────────────────────────────────────────────────────┘
```
