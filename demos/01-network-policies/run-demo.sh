#!/bin/bash
set -e

echo "==========================================="
echo "AKS Cilium - Network Policies Demo"
echo "==========================================="
echo ""

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
MANIFESTS_DIR="$SCRIPT_DIR/../../manifests/network-policies"

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
command -v cilium >/dev/null 2>&1 || { print_red "cilium CLI is required but not installed. Aborting."; exit 1; }
print_green "Prerequisites check passed"
echo ""

# Step 1: Deploy sample applications
print_yellow "Step 1: Deploying sample applications..."
kubectl apply -f "$MANIFESTS_DIR/00-namespace.yaml"
kubectl apply -f "$MANIFESTS_DIR/01-sample-apps.yaml"
print_green "Applications deployed"
echo ""

# Wait for pods to be ready
print_yellow "Waiting for pods to be ready..."
kubectl wait --for=condition=ready pod -l tier=frontend -n demo-app --timeout=120s
kubectl wait --for=condition=ready pod -l tier=backend -n demo-app --timeout=120s
kubectl wait --for=condition=ready pod -l tier=database -n demo-app --timeout=120s
print_green "All pods are ready"
echo ""

# Step 2: Test connectivity before policies
print_yellow "Step 2: Testing connectivity BEFORE network policies..."
echo "Testing frontend -> backend connection..."
if kubectl exec -n demo-app deployment/frontend -- wget -O- --timeout=5 http://backend:5678 > /dev/null 2>&1; then
    print_green "Frontend can reach backend (expected)"
else
    print_red "Frontend cannot reach backend (unexpected)"
fi

echo "Testing frontend -> database connection..."
if kubectl exec -n demo-app deployment/frontend -- nc -zv -w 3 database 5432 > /dev/null 2>&1; then
    print_green "Frontend can reach database (expected but not ideal)"
else
    print_red "Frontend cannot reach database"
fi
echo ""

# Step 3: Apply default deny policy
print_yellow "Step 3: Applying default deny policy..."
kubectl apply -f "$MANIFESTS_DIR/02-default-deny.yaml"
sleep 5
print_green "Default deny policy applied"
echo ""

# Step 4: Test connectivity after default deny
print_yellow "Step 4: Testing connectivity AFTER default deny..."
echo "Testing frontend -> backend connection..."
if kubectl exec -n demo-app deployment/frontend -- timeout 3 wget -O- http://backend:5678 > /dev/null 2>&1; then
    print_red "Frontend can reach backend (unexpected - policy not working)"
else
    print_green "Frontend cannot reach backend (expected - policy working)"
fi
echo ""

# Step 5: Apply selective allow policies
print_yellow "Step 5: Applying selective allow policies..."
kubectl apply -f "$MANIFESTS_DIR/03-allow-specific-traffic.yaml"
kubectl apply -f "$MANIFESTS_DIR/04-allow-dns.yaml"
sleep 5
print_green "Selective allow policies applied"
echo ""

# Step 6: Test connectivity after allow policies
print_yellow "Step 6: Testing connectivity AFTER allow policies..."
echo "Testing frontend -> backend connection..."
if kubectl exec -n demo-app deployment/frontend -- wget -O- --timeout=5 http://backend:5678 > /dev/null 2>&1; then
    print_green "Frontend can reach backend (expected)"
else
    print_red "Frontend cannot reach backend (unexpected)"
fi

echo "Testing frontend -> database connection..."
if kubectl exec -n demo-app deployment/frontend -- timeout 3 nc -zv database 5432 > /dev/null 2>&1; then
    print_red "Frontend can reach database (unexpected - should be blocked)"
else
    print_green "Frontend cannot reach database (expected - policy working)"
fi
echo ""

# Step 7: Apply L7 policy
print_yellow "Step 7: Applying Layer 7 HTTP policy..."
kubectl apply -f "$MANIFESTS_DIR/05-l7-policy.yaml"
sleep 5
print_green "L7 policy applied"
echo ""

# Step 8: Apply FQDN policy
print_yellow "Step 8: Applying FQDN-based egress policy..."
kubectl apply -f "$MANIFESTS_DIR/06-fqdn-policy.yaml"
sleep 5
print_green "FQDN policy applied"
echo ""

# Step 9: Visualize with Hubble
print_yellow "Step 9: Network policy visualization"
echo "To visualize network flows, run the following commands:"
echo ""
echo "  # Start Hubble UI"
echo "  cilium hubble ui"
echo ""
echo "  # Watch flows in real-time"
echo "  cilium hubble observe --namespace demo-app --follow"
echo ""
echo "  # Generate traffic"
echo "  kubectl exec -it -n demo-app deployment/frontend -- sh -c 'while true; do wget -O- http://backend:5678; sleep 2; done'"
echo ""

print_green "Demo completed successfully!"
echo ""
echo "To view Cilium network policies:"
echo "  kubectl get cnp -n demo-app"
echo ""
echo "To cleanup:"
echo "  kubectl delete namespace demo-app"
