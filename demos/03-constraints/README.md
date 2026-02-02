# OPA Gatekeeper Constraints Demo

Demo script for OPA Gatekeeper policy enforcement on AKS.

## What This Demo Shows

1. Deploying constraint templates
2. Creating constraint instances
3. Testing policy enforcement
4. Viewing violations
5. Using dry-run mode
6. Monitoring compliance

## Prerequisites

- AKS cluster with Gatekeeper deployed (via Terraform)
- kubectl configured

## Running the Demo

### Option 1: Automated Script

```bash
chmod +x run-demo.sh
./run-demo.sh
```

### Option 2: Manual Steps

Follow the instructions in `../../manifests/constraints/README.md`

## Policies Demonstrated

1. **Required Labels**: All resources must have `app` and `environment` labels
2. **Allowed Repos**: Only approved container registries
3. **Container Limits**: All containers must have resource limits
4. **Block Privileged**: No privileged containers allowed

## Expected Outcomes

- ✗ Deployments without required labels are rejected
- ✗ Containers without resource limits are rejected
- ✗ Privileged containers are rejected
- ✗ Images from untrusted registries are rejected
- ✓ Compliant resources are created successfully

## Viewing Violations

```bash
# View all violations
kubectl get constraints

# View specific constraint
kubectl get k8srequiredlabels require-common-labels -o yaml

# Check audit logs
kubectl logs -n gatekeeper-system -l control-plane=audit-controller
```

## Dry-Run Mode

Test policies without enforcement:

```bash
kubectl patch k8srequiredlabels require-common-labels \
  --type='json' \
  -p='[{"op": "replace", "path": "/spec/enforcementAction", "value": "dryrun"}]'
```

## Cleanup

```bash
kubectl delete -f ../../manifests/constraints/constraints/
kubectl delete -f ../../manifests/constraints/templates/
```
