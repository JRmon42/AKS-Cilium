#!/bin/bash
set -e

echo "==========================================="
echo "AKS - Azure Policy Demo"
echo "==========================================="
echo ""

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

print_blue() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Check prerequisites
print_yellow "Checking prerequisites..."
command -v kubectl >/dev/null 2>&1 || { print_red "kubectl is required but not installed. Aborting."; exit 1; }
print_green "Prerequisites check passed"
echo ""

# Step 1: Verify Azure Policy
print_yellow "Step 1: Verifying Azure Policy integration..."
if kubectl get namespace gatekeeper-system > /dev/null 2>&1; then
    print_green "Gatekeeper is installed (managed by Azure Policy)"
else
    print_red "Gatekeeper not found. Azure Policy may not be enabled."
    exit 1
fi
echo ""

# Step 2: List Azure Policy Constraint Templates
print_yellow "Step 2: Available Azure Policy Constraint Templates..."
echo ""
kubectl get constrainttemplates | grep k8sazure | awk '{print "  - " $1}' | head -20
echo ""
print_green "$(kubectl get constrainttemplates | grep -c k8sazure) Azure Policy templates available"
echo ""

# Step 3: View Active Constraints
print_yellow "Step 3: Active Azure Policy Constraints..."
echo ""
CONSTRAINT_COUNT=$(kubectl get constraints --all-namespaces 2>/dev/null | grep -c azurepolicy || echo "0")
if [ "$CONSTRAINT_COUNT" -gt 0 ]; then
    print_green "Found $CONSTRAINT_COUNT active constraints"
    echo ""
    kubectl get constraints --all-namespaces 2>/dev/null | grep azurepolicy | head -10
    echo ""
else
    print_yellow "No active constraints found"
fi
echo ""

# Step 4: Check Enforcement Mode
print_yellow "Step 4: Checking enforcement modes..."
echo ""
echo "Current enforcement status:"
echo ""
kubectl get constraints --all-namespaces 2>/dev/null | grep azurepolicy | awk '{print $1 "\t" $2}' | while read line; do
    echo "  $line"
done | head -10
echo ""
print_blue "Note: 'dryrun' = audit only, 'deny' = actively blocking"
echo ""

# Step 5: Test Privileged Container Block
print_yellow "Step 5: Testing Azure Policy - Block Privileged Containers..."
echo ""

# Create demo namespace if it doesn't exist
kubectl create namespace demo-app --dry-run=client -o yaml | kubectl apply -f - > /dev/null 2>&1

echo "Test 1: Attempting to create a PRIVILEGED pod..."
cat <<EOF | kubectl apply -f - 2>&1 && print_yellow "WARNING: Pod was created (policy in dryrun mode)" || print_green "✓ Correctly blocked by policy"
apiVersion: v1
kind: Pod
metadata:
  name: test-privileged-azure
  namespace: demo-app
spec:
  containers:
  - name: nginx
    image: nginx:alpine
    securityContext:
      privileged: true
EOF
echo ""

# Step 6: Test Container Limits
print_yellow "Step 6: Testing Azure Policy - Container Limits..."
echo ""
echo "Test 2: Attempting to create pod WITHOUT resource limits..."
cat <<EOF | kubectl apply -f - 2>&1 && print_yellow "WARNING: Pod was created (policy in dryrun mode)" || print_green "✓ Correctly blocked by policy"
apiVersion: v1
kind: Pod
metadata:
  name: test-no-limits-azure
  namespace: demo-app
spec:
  containers:
  - name: nginx
    image: nginx:alpine
EOF
echo ""

# Step 7: Test Default Namespace Block
print_yellow "Step 7: Testing Azure Policy - Block Default Namespace..."
echo ""
echo "Test 3: Attempting to create pod in DEFAULT namespace..."
cat <<EOF | kubectl apply -f - 2>&1 && print_yellow "WARNING: Pod was created (policy in dryrun mode)" || print_green "✓ Correctly blocked by policy"
apiVersion: v1
kind: Pod
metadata:
  name: test-default-ns-azure
  namespace: default
spec:
  containers:
  - name: nginx
    image: nginx:alpine
    resources:
      limits:
        memory: "128Mi"
        cpu: "200m"
EOF
echo ""

# Step 8: View Policy Violations
print_yellow "Step 8: Checking for policy violations..."
echo ""

# Get violations from constraints
echo "Violations detected by Azure Policy:"
echo ""
kubectl get constraints --all-namespaces -o json 2>/dev/null | \
  jq -r '.items[] | select(.status.totalViolations != null and .status.totalViolations > 0) | 
  "\(.kind): \(.status.totalViolations) violations"' | head -10 || echo "  No violations found"
echo ""

# Step 9: Cleanup test resources
print_yellow "Step 9: Cleaning up test resources..."
kubectl delete pod test-privileged-azure -n demo-app --ignore-not-found=true > /dev/null 2>&1
kubectl delete pod test-no-limits-azure -n demo-app --ignore-not-found=true > /dev/null 2>&1
kubectl delete pod test-default-ns-azure -n default --ignore-not-found=true > /dev/null 2>&1
print_green "Test resources cleaned up"
echo ""

# Step 10: Azure Portal Instructions
print_yellow "Step 10: Managing Azure Policy"
echo ""
print_blue "Azure Policy is managed through Azure Portal or Azure CLI, not kubectl."
echo ""
echo "To view and manage policies:"
echo ""
echo "  📊 Azure Portal:"
echo "     1. Go to https://portal.azure.com"
echo "     2. Navigate to your AKS cluster"
echo "     3. Security → Azure Policy"
echo "     4. Review compliance and assign new policies"
echo ""
echo "  💻 Azure CLI:"
echo "     # List assigned policies"
echo "     az policy assignment list --resource-group rg-aks-cilium-demo"
echo ""
echo "     # Assign a new policy"
echo "     az policy assignment create \\"
echo "       --name 'enforce-container-limits' \\"
echo "       --policy '<policy-definition-id>' \\"
echo "       --scope '<cluster-resource-id>'"
echo ""

# Step 11: Available Policies
print_yellow "Step 11: Commonly Used Azure Policies for AKS"
echo ""
echo "Built-in policies you can assign:"
echo ""
echo "  1. Kubernetes cluster containers should only use allowed images"
echo "  2. Kubernetes cluster should not allow privileged containers"
echo "  3. Kubernetes cluster containers CPU and memory resource limits"
echo "  4. Kubernetes cluster pods should only use approved host network"
echo "  5. Kubernetes cluster pods should use specified labels"
echo "  6. Kubernetes cluster services should only use allowed ports"
echo ""
print_blue "Browse all policies: https://portal.azure.com/#view/Microsoft_Azure_Policy"
echo ""

print_green "Azure Policy demo completed!"
echo ""
echo "📚 Key Takeaways:"
echo ""
echo "  ✓ Azure Policy uses Gatekeeper under the hood"
echo "  ✓ Policies are managed through Azure Portal/CLI, not kubectl"
echo "  ✓ Current policies are in 'dryrun' mode (audit only)"
echo "  ✓ Change to 'deny' mode in Azure Portal to enforce"
echo ""
echo "🔗 Documentation:"
echo "  - https://learn.microsoft.com/azure/governance/policy/concepts/policy-for-kubernetes"
echo "  - docs/AZURE-POLICY.md (in this repo)"
echo ""
