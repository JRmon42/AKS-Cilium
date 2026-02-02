# Monitoring Setup

This directory contains monitoring configurations for the AKS cluster with Cilium.

## Components

- **Prometheus**: Metrics collection and alerting
- **Grafana**: Visualization and dashboards
- **Azure Monitor**: Container Insights integration
- **Hubble**: Cilium network observability

## Setup

The monitoring stack is automatically deployed via Terraform, but you can also deploy manually:

```bash
# Apply Grafana dashboards
kubectl apply -f grafana-dashboards.yaml

# Apply Prometheus configuration
kubectl apply -f prometheus-config.yaml

# Apply ServiceMonitors for Cilium
kubectl apply -f servicemonitors.yaml
```

## Access Dashboards

### Grafana

```bash
# Port forward to Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80

# Access at http://localhost:3000
# Default credentials: admin/admin
```

### Prometheus

```bash
# Port forward to Prometheus
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090

# Access at http://localhost:9090
```

### Hubble UI

```bash
# Enable Hubble UI (if not already enabled)
cilium hubble enable --ui

# Port forward to Hubble UI
cilium hubble ui

# Access at http://localhost:12000
```

### Azure Monitor

```bash
# Open Azure Portal
az aks show --resource-group rg-aks-cilium-demo --name aks-cilium-demo --query "id" -o tsv

# Navigate to: Monitoring > Insights in Azure Portal
```

## Key Metrics to Monitor

### Cilium Metrics

- `cilium_agent_api_process_time_seconds`: API processing time
- `cilium_drop_count_total`: Dropped packets by reason
- `cilium_policy_enforcement_status`: Policy enforcement status
- `cilium_endpoint_state`: Endpoint states
- `cilium_policy_max_revision`: Active policy revision

### Hubble Metrics

- `hubble_flows_processed_total`: Total flows processed
- `hubble_drop_total`: Dropped flows
- `hubble_tcp_flags`: TCP flag statistics

### Kubernetes Metrics

- `container_cpu_usage_seconds_total`: CPU usage
- `container_memory_working_set_bytes`: Memory usage
- `kube_pod_status_phase`: Pod status
- `kube_deployment_status_replicas`: Deployment replicas

## Sample Prometheus Queries

### Network Policy Drops
```promql
rate(cilium_drop_count_total{reason="Policy denied"}[5m])
```

### Top CPU Consuming Pods
```promql
topk(10, sum(rate(container_cpu_usage_seconds_total[5m])) by (pod, namespace))
```

### Top Memory Consuming Pods
```promql
topk(10, sum(container_memory_working_set_bytes) by (pod, namespace))
```

### Network Traffic by Pod
```promql
sum(rate(container_network_receive_bytes_total[5m])) by (pod)
```

## Alerts

The Prometheus stack includes default alerts for:
- High CPU/Memory usage
- Pod restart loops
- Node resource pressure
- Failed network policies

## Troubleshooting

### Check Prometheus Targets

```bash
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090

# Visit http://localhost:9090/targets
```

### View Cilium Metrics

```bash
# Get metrics directly from Cilium agent
kubectl exec -n kube-system ds/cilium -- cilium metrics list
```

### Check Hubble Status

```bash
cilium hubble port-forward &
hubble status
```

## Custom Dashboards

Import additional dashboards from:
- [Grafana Dashboard Repository](https://grafana.com/grafana/dashboards/)
- Cilium Dashboard ID: 16611
- Kubernetes Dashboard ID: 15760

```bash
# Import via Grafana UI or CLI
# Dashboard > Import > Enter Dashboard ID
```
