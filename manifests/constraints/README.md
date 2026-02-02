# OPA Gatekeeper Constraints

This directory contains OPA Gatekeeper policy constraints and templates for enforcing Kubernetes security and compliance policies.

## Structure

- **templates/**: ConstraintTemplate definitions (Rego policies)
- **constraints/**: Constraint instances (policy enforcement)

## Constraint Templates

### 1. Required Labels (`K8sRequiredLabels`)
Enforces that specific labels are present on resources.

**Use Case**: Ensure all resources have proper labels for cost tracking, ownership, and organization.

### 2. Allowed Repos (`K8sAllowedRepos`)
Restricts container images to approved registries.

**Use Case**: Prevent use of untrusted or public container images.

### 3. Container Limits (`K8sContainerLimits`)
Requires CPU and memory limits/requests on all containers.

**Use Case**: Prevent resource exhaustion and ensure proper resource planning.

### 4. Block Privileged (`K8sBlockPrivileged`)
Blocks privileged containers.

**Use Case**: Enhance security by preventing privileged escalation.

## Quick Start

### 1. Deploy Templates

```bash
# Apply all constraint templates
kubectl apply -f templates/
```

### 2. Verify Templates

```bash
kubectl get constrainttemplates
```

### 3. Deploy Constraints

```bash
# Apply all constraints
kubectl apply -f constraints/
```

### 4. Verify Constraints

```bash
kubectl get constraints
```

## Testing Constraints

### Test Required Labels

```bash
# This should FAIL (missing labels)
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test-no-labels
  namespace: demo-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: test
  template:
    metadata:
      labels:
        app: test
    spec:
      containers:
      - name: nginx
        image: nginx
EOF

# This should SUCCEED
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test-with-labels
  namespace: demo-app
  labels:
    app: test
    environment: demo
spec:
  replicas: 1
  selector:
    matchLabels:
      app: test
  template:
    metadata:
      labels:
        app: test
        environment: demo
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        resources:
          requests:
            memory: "64Mi"
            cpu: "100m"
          limits:
            memory: "128Mi"
            cpu: "200m"
EOF
```

### Test Allowed Repos

```bash
# This should FAIL (untrusted registry)
kubectl run test-bad-repo --image=evil.registry.com/malware:latest -n demo-app

# This should SUCCEED (allowed registry)
kubectl run test-good-repo --image=docker.io/nginx:alpine -n demo-app --dry-run=client
```

### Test Resource Limits

```bash
# This should FAIL (no resource limits)
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: test-no-limits
  namespace: demo-app
  labels:
    app: test
    environment: demo
spec:
  containers:
  - name: nginx
    image: nginx:alpine
EOF

# This should SUCCEED (has resource limits)
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: test-with-limits
  namespace: demo-app
  labels:
    app: test
    environment: demo
spec:
  containers:
  - name: nginx
    image: nginx:alpine
    resources:
      requests:
        memory: "64Mi"
        cpu: "100m"
      limits:
        memory: "128Mi"
        cpu: "200m"
EOF
```

### Test Privileged Containers

```bash
# This should FAIL (privileged container)
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: test-privileged
  namespace: demo-app
  labels:
    app: test
    environment: demo
spec:
  containers:
  - name: privileged
    image: nginx:alpine
    securityContext:
      privileged: true
EOF
```

## View Violations

### Check Audit Violations

```bash
# View all violations
kubectl get constraints -A -o json | jq '.items[] | select(.status.totalViolations > 0) | {kind: .kind, name: .metadata.name, violations: .status.violations}'

# View specific constraint violations
kubectl get k8srequiredlabels require-common-labels -o yaml
```

### Gatekeeper Audit Log

```bash
# Check Gatekeeper audit logs
kubectl logs -n gatekeeper-system -l control-plane=audit-controller
```

## Enforcement Modes

Constraints can operate in two modes:

### 1. Enforce (Default)
Blocks non-compliant resources from being created.

```yaml
spec:
  enforcementAction: deny  # Default
```

### 2. Dry Run (Audit Only)
Logs violations but allows resource creation.

```yaml
spec:
  enforcementAction: dryrun
```

### 3. Warn
Shows warnings but allows resource creation.

```yaml
spec:
  enforcementAction: warn
```

## Best Practices

1. **Start with Dry Run**: Test policies in dryrun mode first
   ```bash
   # Modify constraint to use dryrun
   kubectl patch k8srequiredlabels require-common-labels --type='json' -p='[{"op": "replace", "path": "/spec/enforcementAction", "value": "dryrun"}]'
   ```

2. **Gradual Rollout**: Enable constraints namespace by namespace

3. **Monitor Violations**: Regularly check for audit violations
   ```bash
   kubectl get constraints -A
   ```

4. **Document Exceptions**: Use excluded namespaces for system components

5. **Test Before Enforcing**: Always test in non-production first

## Custom Policies

To create custom policies:

1. Create a ConstraintTemplate with Rego policy
2. Test the template
3. Create a Constraint instance
4. Start in dryrun mode
5. Monitor violations
6. Switch to enforce mode

## Common Policies to Add

- Ingress hostname uniqueness
- Required annotations
- Replica count limits
- Image pull policy
- Host namespace restrictions
- Volume type restrictions
- Capabilities restrictions

## Troubleshooting

### Policy Not Working

```bash
# Check template status
kubectl get constrainttemplate k8srequiredlabels -o yaml

# Check constraint status
kubectl get k8srequiredlabels require-common-labels -o yaml

# Check Gatekeeper logs
kubectl logs -n gatekeeper-system -l control-plane=controller-manager
```

### View Cached Resources

```bash
# Check what resources Gatekeeper is tracking
kubectl get configs.config.gatekeeper.sh config -n gatekeeper-system -o yaml
```

## References

- [OPA Gatekeeper Documentation](https://open-policy-agent.github.io/gatekeeper/website/docs/)
- [Gatekeeper Library](https://github.com/open-policy-agent/gatekeeper-library)
- [Rego Playground](https://play.openpolicyagent.org/)
