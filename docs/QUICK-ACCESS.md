# Quick Access Guide - All UIs and Dashboards

This guide provides quick commands and URLs for accessing all management interfaces for your AKS cluster with Azure CNS and Cilium.

## 🌐 Azure Portal

### Main Cluster View
```
https://portal.azure.com/#@/resource/subscriptions/{subscription-id}/resourceGroups/rg-aks-cilium-demo/providers/Microsoft.ContainerService/managedClusters/aks-cilium-demo
```

**Quick Navigation:**
1. Go to [portal.azure.com](https://portal.azure.com)
2. Search for `aks-cilium-demo`
3. Click on the cluster name

### Key Portal Pages

| Section | What to View | Direct Path |
|---------|-------------|-------------|
| **Overview** | Cluster status, essentials | Cluster → Overview |
| **Workloads** | Pods, deployments, services | Cluster → Kubernetes resources → Workloads |
| **Networking** | Network policies, services | Cluster → Kubernetes resources → Services and ingresses |
| **Monitoring** | Container Insights | Cluster → Monitoring → Insights |
| **Logs** | Log Analytics queries | Cluster → Monitoring → Logs |
| **Metrics** | Performance metrics | Cluster → Monitoring → Metrics |
| **Configuration** | Node pools, settings | Cluster → Settings |
| **Security** | Azure Policy, compliance | Cluster → Security |

## 📊 Grafana Dashboard

### Access Grafana

**Port Forward Method:**
```bash
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
```

**Access URL:**
```
http://localhost:3000
```

**Login Credentials:**
- **Username**: `admin`
- **Password**: `prom-operator`

### Pre-installed Dashboards

| Dashboard | Description | ID/Name |
|-----------|-------------|---------|
| **Cluster Overview** | Overall cluster health | Kubernetes / Compute Resources / Cluster |
| **Node Exporter** | Node-level metrics | Node Exporter / Nodes |
| **Pod Resources** | Pod CPU/Memory | Kubernetes / Compute Resources / Pod |
| **Namespace Resources** | Per-namespace metrics | Kubernetes / Compute Resources / Namespace |
| **Cilium Metrics** | Cilium agent metrics | Cilium Agent Metrics |
| **Persistent Volumes** | Storage metrics | Kubernetes / Persistent Volumes |

### Grafana Tips
- **Create custom dashboards**: Dashboard → New → Dashboard
- **Import dashboards**: Dashboard → Import → Enter ID
- **Alerts**: Configure alerts for metrics thresholds
- **Variables**: Use variables for multi-cluster/namespace views

## 🔍 Hubble UI (Network Observability)

### Access Hubble UI

**Using Cilium CLI:**
```bash
cilium hubble ui
```

This automatically:
1. Enables port forwarding to Hubble UI
2. Opens browser at `http://localhost:12000`

**Manual Port Forward:**
```bash
kubectl port-forward -n kube-system svc/hubble-ui 12000:80
```

**Access URL:**
```
http://localhost:12000
```

### Hubble UI Features

| Feature | Description | Use Case |
|---------|-------------|----------|
| **Service Map** | Visual graph of service communication | Understand service dependencies |
| **Flow View** | Real-time network flows | Debug connectivity issues |
| **Filters** | Filter by namespace, pod, verdict | Focus on specific traffic |
| **Verdicts** | View allowed/denied flows | Troubleshoot network policies |
| **Protocols** | HTTP, gRPC, Kafka details | L7 visibility |

### Hubble CLI Commands

```bash
# Watch real-time flows
cilium hubble observe

# Filter by namespace
cilium hubble observe --namespace default

# Show only dropped packets
cilium hubble observe --verdict DROPPED

# Filter by pod label
cilium hubble observe --from-label app=frontend

# Export flows to JSON
cilium hubble observe -o json > flows.json
```

## 📈 Prometheus

### Access Prometheus UI

**Port Forward:**
```bash
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
```

**Access URL:**
```
http://localhost:9090
```

### Useful Prometheus Queries

```promql
# Pod CPU usage by namespace
sum(rate(container_cpu_usage_seconds_total[5m])) by (namespace)

# Pod memory usage
sum(container_memory_working_set_bytes) by (pod, namespace)

# Network bytes received
sum(rate(container_network_receive_bytes_total[5m])) by (pod)

# Cilium drops
sum(rate(cilium_drop_count_total[5m])) by (reason)

# Node CPU usage
100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
```

## 🎯 Kubernetes Dashboard (Optional)

If you want to install the official Kubernetes Dashboard:

### Install

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml
```

### Create Admin User

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
EOF
```

### Get Access Token

```bash
kubectl -n kubernetes-dashboard create token admin-user
```

### Access Dashboard

```bash
kubectl proxy
```

**Access URL:**
```
http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
```

## 🖥️ CLI Tools Quick Reference

### Kubectl

```bash
# Get cluster info
kubectl cluster-info

# View all resources
kubectl get all --all-namespaces

# Get events
kubectl get events --all-namespaces --sort-by='.lastTimestamp'

# Describe node
kubectl describe node <node-name>

# Get logs
kubectl logs <pod-name> -n <namespace> -f
```

### Cilium CLI

```bash
# Check status
cilium status

# Enable Hubble
cilium hubble enable

# Check connectivity
cilium connectivity test

# View network policies
cilium network policy list

# Troubleshoot endpoint
cilium endpoint list
```

### Azure CLI

```bash
# Get credentials
az aks get-credentials --resource-group rg-aks-cilium-demo --name aks-cilium-demo

# Browse in Portal
az aks browse --resource-group rg-aks-cilium-demo --name aks-cilium-demo

# Check node health
az aks show --resource-group rg-aks-cilium-demo --name aks-cilium-demo --query agentPoolProfiles

# Scale cluster
az aks scale --resource-group rg-aks-cilium-demo --name aks-cilium-demo --node-count 5
```

## 📱 Azure Mobile App

Download the Azure mobile app for on-the-go management:
- **iOS**: [App Store](https://apps.apple.com/app/microsoft-azure/id1219013620)
- **Android**: [Google Play](https://play.google.com/store/apps/details?id=com.microsoft.azure)

**Features:**
- View cluster status
- Check container insights
- Monitor alerts
- View activity log
- Start/stop resources
- Access Cloud Shell

## 🔔 Setting Up Alerts

### Azure Monitor Alerts

1. Go to **Azure Portal** → AKS Cluster → **Monitoring** → **Alerts**
2. Click **+ New alert rule**
3. Configure conditions:
   - Pod CPU > 80%
   - Node Memory > 85%
   - Pod restart count > 5
   - Network policy denials > threshold

### Prometheus Alertmanager

**Access AlertManager:**
```bash
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-alertmanager 9093:9093
```

**Access URL:**
```
http://localhost:9093
```

## 📊 All Access Commands Summary

Here's a script to open all UIs at once:

```bash
#!/bin/bash

# Grafana
echo "Starting Grafana port-forward..."
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80 &

# Hubble UI
echo "Starting Hubble UI..."
cilium hubble ui &

# Prometheus
echo "Starting Prometheus port-forward..."
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090 &

# AlertManager
echo "Starting AlertManager port-forward..."
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-alertmanager 9093:9093 &

echo ""
echo "======================================"
echo "All services started!"
echo "======================================"
echo ""
echo "Access the following URLs:"
echo ""
echo "  Grafana:       http://localhost:3000"
echo "                 (admin / prom-operator)"
echo ""
echo "  Hubble UI:     http://localhost:12000"
echo ""
echo "  Prometheus:    http://localhost:9090"
echo ""
echo "  AlertManager:  http://localhost:9093"
echo ""
echo "  Azure Portal:  https://portal.azure.com"
echo ""
echo "Press Ctrl+C to stop all services"
echo "======================================"

# Wait for user interrupt
wait
```

Save this as `scripts/open-all-uis.sh` and run:

```bash
chmod +x scripts/open-all-uis.sh
./scripts/open-all-uis.sh
```

## 🛑 Stop All Port Forwards

```bash
# Kill all kubectl port-forward processes
pkill -f "kubectl port-forward"

# Or find specific PIDs
ps aux | grep "kubectl port-forward"
kill <PID>
```

## 📝 Bookmarks

Create browser bookmarks for quick access:

| Name | URL |
|------|-----|
| Azure Portal - AKS | https://portal.azure.com → Search "aks-cilium-demo" |
| Grafana (local) | http://localhost:3000 |
| Hubble UI (local) | http://localhost:12000 |
| Prometheus (local) | http://localhost:9090 |

## 💡 Pro Tips

1. **Use tmux/screen**: Keep port-forwards running in background sessions
2. **SSH tunneling**: Access from remote machines via SSH tunnels
3. **Cloud Shell**: Use Azure Cloud Shell for browser-based kubectl access
4. **VS Code Extension**: Install Kubernetes extension for in-editor management
5. **Aliases**: Create shell aliases for commonly used commands

```bash
# Add to .bashrc or .zshrc
alias grafana='kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80'
alias hubble='cilium hubble ui'
alias prom='kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090'
```

---

For detailed operational guidance, see:
- [Azure Portal Management Guide](PORTAL-GUIDE.md)
- [Azure CNS Documentation](AZURE-CNS.md)
