#!/bin/bash
set -e

echo "==========================================="
echo "AKS Cilium - Monitoring Demo"
echo "==========================================="
echo ""

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

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

# Step 1: Verify monitoring namespace
print_yellow "Step 1: Verifying monitoring stack..."
if kubectl get namespace monitoring > /dev/null 2>&1; then
    print_green "Monitoring namespace exists"
else
    print_red "Monitoring namespace not found. Run Terraform first."
    exit 1
fi
echo ""

# Step 2: Check Prometheus
print_yellow "Step 2: Checking Prometheus status..."
if kubectl get pods -n monitoring -l app.kubernetes.io/name=prometheus > /dev/null 2>&1; then
    print_green "Prometheus is deployed"
    kubectl get pods -n monitoring -l app.kubernetes.io/name=prometheus
else
    print_red "Prometheus not found"
fi
echo ""

# Step 3: Check Grafana
print_yellow "Step 3: Checking Grafana status..."
if kubectl get pods -n monitoring -l app.kubernetes.io/name=grafana > /dev/null 2>&1; then
    print_green "Grafana is deployed"
    kubectl get pods -n monitoring -l app.kubernetes.io/name=grafana
else
    print_red "Grafana not found"
fi
echo ""

# Step 4: Check Cilium metrics
print_yellow "Step 4: Checking Cilium metrics availability..."
CILIUM_POD=$(kubectl get pods -n kube-system -l k8s-app=cilium -o jsonpath='{.items[0].metadata.name}')
if [ -n "$CILIUM_POD" ]; then
    print_green "Cilium pod found: $CILIUM_POD"
    echo ""
    print_yellow "Sample Cilium metrics:"
    kubectl exec -n kube-system "$CILIUM_POD" -- cilium metrics list | head -20
else
    print_red "Cilium pod not found"
fi
echo ""

# Step 5: Enable Hubble UI
print_yellow "Step 5: Checking Hubble status..."
if cilium hubble port-forward > /dev/null 2>&1 &
PF_PID=$!
sleep 3
then
    print_green "Hubble port-forward started"
    kill $PF_PID 2>/dev/null || true
else
    print_yellow "Hubble may not be enabled. Enabling..."
    cilium hubble enable --ui
fi
echo ""

# Step 6: Access instructions
print_yellow "Step 6: Access Instructions"
echo ""
echo "=== Grafana ==="
echo "Run: kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80"
echo "URL: http://localhost:3000"
echo "Default credentials: admin / admin"
echo ""
echo "=== Prometheus ==="
echo "Run: kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090"
echo "URL: http://localhost:9090"
echo ""
echo "=== Hubble UI ==="
echo "Run: cilium hubble ui"
echo "URL: http://localhost:12000"
echo ""
echo "=== Azure Monitor ==="
echo "Run: az aks show --resource-group rg-aks-cilium-demo --name aks-cilium-demo --query id -o tsv"
echo "Then navigate to Azure Portal > AKS > Insights"
echo ""

# Step 7: Sample queries
print_yellow "Step 7: Sample Prometheus Queries"
echo ""
echo "Network Policy Drops:"
echo '  rate(cilium_drop_count_total{reason="Policy denied"}[5m])'
echo ""
echo "Top CPU Pods:"
echo '  topk(10, sum(rate(container_cpu_usage_seconds_total[5m])) by (pod, namespace))'
echo ""
echo "Top Memory Pods:"
echo '  topk(10, sum(container_memory_working_set_bytes) by (pod, namespace))'
echo ""
echo "Cilium Agent Status:"
echo '  cilium_agent_api_process_time_seconds_count'
echo ""

# Step 8: Generate sample metrics
print_yellow "Step 8: Generating sample metrics (optional)"
echo "To generate sample traffic and metrics, run:"
echo ""
echo "  kubectl run load-generator --image=busybox --restart=Never -- /bin/sh -c 'while true; do wget -q -O- http://backend.demo-app:5678; done'"
echo ""
echo "Then observe metrics in Grafana and Hubble"
echo ""

print_green "Monitoring demo completed!"
echo ""
echo "Next steps:"
echo "1. Open Grafana and explore dashboards"
echo "2. Open Hubble UI and visualize network flows"
echo "3. Check Azure Monitor Container Insights"
echo "4. Create custom alerts in Prometheus"
