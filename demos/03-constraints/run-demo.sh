#!/bin/bash
set -e

echo "==========================================="
echo "AKS Cilium - OPA Gatekeeper Constraints Demo"
echo "==========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_green() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_red() {
    echo -e "${RED}✗ $1${NC}"
}

print_yellow() {
    echo -e "${YELLOW}➜ $1${NC}"
}

# Check prerequisites
print_yellow "Checking prerequisites..."
command -v kubectl >/dev/null 2>&1 || { print_red "kubectl is required but not installed. Aborting."; exit 1; }
print_green "Prerequisites check passed"
echo ""

# Step 1: Verify Gatekeeper
print_yellow "Step 1: Verifying Gatekeeper installation..."
if kubectl get namespace gatekeeper-system > /dev/null 2>&1; then
    print_green "Gatekeeper is installed"
    kubectl get pods -n gatekeeper-system
else
    print_red "Gatekeeper not found. Run Terraform first."
    exit 1
fi
echo ""

# Step 2: Deploy constraint templates
print_yellow "Step 2: Deploying constraint templates..."
kubectl apply -f ../../manifests/constraints/templates/
sleep 5
print_green "Constraint templates deployed"
kubectl get constrainttemplates
echo ""

# Step 3: Deploy constraints
print_yellow "Step 3: Deploying constraints..."
kubectl apply -f ../../manifests/constraints/constraints/
sleep 5
print_green "Constraints deployed"
kubectl get constraints
echo ""

# Create demo namespace if it doesn't exist
print_yellow "Creating demo-app namespace if needed..."
kubectl create namespace demo-app --dry-run=client -o yaml | kubectl apply -f -
echo ""

# Step 4: Test Required Labels Constraint
print_yellow "Step 4: Testing Required Labels constraint..."
echo ""
echo "Test 1: Deployment WITHOUT required labels (should FAIL)"
cat <<EOF | kubectl apply -f - 2>&1 || print_green "✓ Correctly rejected (missing labels)"
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
        image: nginx:alpine
        resources:
          requests:
            memory: "64Mi"
            cpu: "100m"
          limits:
            memory: "128Mi"
            cpu: "200m"
EOF
echo ""

echo "Test 2: Deployment WITH required labels (should SUCCEED)"
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
print_green "✓ Deployment created successfully"
echo ""

# Step 5: Test Container Limits Constraint
print_yellow "Step 5: Testing Container Limits constraint..."
echo ""
echo "Test 3: Pod WITHOUT resource limits (should FAIL)"
cat <<EOF | kubectl apply -f - 2>&1 || print_green "✓ Correctly rejected (missing resource limits)"
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
echo ""

# Step 6: Test Privileged Container Constraint
print_yellow "Step 6: Testing Block Privileged constraint..."
echo ""
echo "Test 4: Pod with PRIVILEGED container (should FAIL)"
cat <<EOF | kubectl apply -f - 2>&1 || print_green "✓ Correctly rejected (privileged container blocked)"
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
  - name: nginx
    image: nginx:alpine
    securityContext:
      privileged: true
    resources:
      requests:
        memory: "64Mi"
        cpu: "100m"
      limits:
        memory: "128Mi"
        cpu: "200m"
EOF
echo ""

# Step 7: View constraint status
print_yellow "Step 7: Viewing constraint status..."
echo ""
echo "=== Required Labels Constraint ==="
kubectl get k8srequiredlabels require-common-labels -o yaml | grep -A 10 "status:"
echo ""
echo "=== Container Limits Constraint ==="
kubectl get k8scontainerlimits container-must-have-limits -o yaml | grep -A 10 "status:"
echo ""
echo "=== Block Privileged Constraint ==="
kubectl get k8sblockprivileged block-privileged-containers -o yaml | grep -A 10 "status:"
echo ""

# Step 8: Check for violations
print_yellow "Step 8: Checking for policy violations..."
echo ""
kubectl get constraints --all-namespaces -o json | \
  jq -r '.items[] | select(.status.totalViolations != null and .status.totalViolations > 0) | 
  "\(.kind)/\(.metadata.name): \(.status.totalViolations) violations"'
echo ""

# Step 9: Dry-run mode demonstration
print_yellow "Step 9: Dry-run mode demonstration"
echo ""
echo "To test policies without enforcement, set enforcementAction to 'dryrun':"
echo ""
echo "kubectl patch k8srequiredlabels require-common-labels --type='json' -p='[{\"op\": \"replace\", \"path\": \"/spec/enforcementAction\", \"value\": \"dryrun\"}]'"
echo ""
echo "In dry-run mode, violations are logged but resources are still created."
echo ""

# Cleanup test resources
print_yellow "Cleaning up test resources..."
kubectl delete deployment test-with-labels -n demo-app --ignore-not-found=true
echo ""

print_green "Constraints demo completed successfully!"
echo ""
echo "Next steps:"
echo "1. Check Gatekeeper audit logs: kubectl logs -n gatekeeper-system -l control-plane=audit-controller"
echo "2. View all constraints: kubectl get constraints"
echo "3. Create custom constraint templates for your needs"
echo "4. Monitor violations in production"
echo ""
echo "To cleanup:"
echo "  kubectl delete -f ../../manifests/constraints/constraints/"
echo "  kubectl delete -f ../../manifests/constraints/templates/"
