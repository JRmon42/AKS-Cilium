#!/bin/bash

# Start all monitoring and observability UIs for AKS with Cilium
# This script starts port-forwarding for all web UIs

set -e

echo ""
echo "======================================"
echo "Starting all UI services..."
echo "======================================"
echo ""

# Check if kubectl is configured
if ! kubectl cluster-info &> /dev/null; then
    echo "Error: kubectl is not configured or cluster is not reachable"
    echo "Run: az aks get-credentials --resource-group rg-aks-cilium-demo --name aks-cilium-demo"
    exit 1
fi

# Function to check if port is already in use
check_port() {
    local port=$1
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1 ; then
        echo "Warning: Port $port is already in use"
        return 1
    fi
    return 0
}

# Grafana
echo "🔄 Starting Grafana port-forward (port 3000)..."
if check_port 3000; then
    kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80 > /dev/null 2>&1 &
    GRAFANA_PID=$!
    echo "✅ Grafana started (PID: $GRAFANA_PID)"
fi

# Wait a bit between port-forwards
sleep 2

# Hubble UI
echo "🔄 Starting Hubble UI (port 12000)..."
if command -v cilium &> /dev/null; then
    cilium hubble ui > /dev/null 2>&1 &
    HUBBLE_PID=$!
    echo "✅ Hubble UI started (PID: $HUBBLE_PID)"
else
    echo "⚠️  Cilium CLI not found. Skipping Hubble UI."
    echo "   Install from: https://docs.cilium.io/en/stable/gettingstarted/k8s-install-default/"
fi

# Wait a bit between port-forwards
sleep 2

# Prometheus
echo "🔄 Starting Prometheus port-forward (port 9090)..."
if check_port 9090; then
    kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090 > /dev/null 2>&1 &
    PROM_PID=$!
    echo "✅ Prometheus started (PID: $PROM_PID)"
fi

# Wait a bit between port-forwards
sleep 2

# AlertManager
echo "🔄 Starting AlertManager port-forward (port 9093)..."
if check_port 9093; then
    kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-alertmanager 9093:9093 > /dev/null 2>&1 &
    ALERT_PID=$!
    echo "✅ AlertManager started (PID: $ALERT_PID)"
fi

echo ""
echo "======================================"
echo "✅ All services started successfully!"
echo "======================================"
echo ""
echo "Access the following URLs in your browser:"
echo ""
echo "  📊 Grafana:        http://localhost:3000"
echo "                     Username: admin"
echo "                     Password: prom-operator"
echo ""
echo "  🔍 Hubble UI:      http://localhost:12000"
echo "                     (Network observability)"
echo ""
echo "  📈 Prometheus:     http://localhost:9090"
echo "                     (Metrics and queries)"
echo ""
echo "  🔔 AlertManager:   http://localhost:9093"
echo "                     (Alert management)"
echo ""
echo "  🌐 Azure Portal:   https://portal.azure.com"
echo "                     Search for: aks-cilium-demo"
echo ""
echo "======================================"
echo "Press Ctrl+C to stop all services"
echo "======================================"
echo ""

# Function to cleanup on exit
cleanup() {
    echo ""
    echo "Stopping all services..."
    
    # Kill all port-forward processes we started
    if [ ! -z "$GRAFANA_PID" ]; then
        kill $GRAFANA_PID 2>/dev/null || true
    fi
    if [ ! -z "$HUBBLE_PID" ]; then
        kill $HUBBLE_PID 2>/dev/null || true
    fi
    if [ ! -z "$PROM_PID" ]; then
        kill $PROM_PID 2>/dev/null || true
    fi
    if [ ! -z "$ALERT_PID" ]; then
        kill $ALERT_PID 2>/dev/null || true
    fi
    
    # Also kill any remaining kubectl port-forward processes
    pkill -f "kubectl port-forward.*monitoring" 2>/dev/null || true
    
    echo "All services stopped."
    echo "Goodbye! 👋"
    exit 0
}

# Trap Ctrl+C and call cleanup
trap cleanup INT TERM

# Wait for user interrupt
wait
