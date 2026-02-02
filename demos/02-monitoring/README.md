# Monitoring Demo

Demo script for monitoring AKS with Cilium using Prometheus, Grafana, and Hubble.

## What This Demo Shows

1. Verifying the monitoring stack deployment
2. Accessing Grafana dashboards
3. Querying Prometheus metrics
4. Using Hubble for network observability
5. Azure Monitor Container Insights
6. Sample queries and visualizations

## Prerequisites

- AKS cluster deployed with monitoring stack (via Terraform)
- kubectl configured
- Cilium CLI installed

## Running the Demo

### Option 1: Automated Script

```bash
chmod +x run-demo.sh
./run-demo.sh
```

### Option 2: Manual Steps

1. Check monitoring stack:
   ```bash
   kubectl get pods -n monitoring
   ```

2. Access Grafana:
   ```bash
   kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
   ```
   Open http://localhost:3000 (admin/admin)

3. Access Prometheus:
   ```bash
   kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
   ```
   Open http://localhost:9090

4. Access Hubble UI:
   ```bash
   cilium hubble ui
   ```
   Open http://localhost:12000

## Key Metrics to Explore

### Cilium Metrics
- Network policy drops
- Endpoint state
- Policy enforcement status

### Kubernetes Metrics
- CPU/Memory usage by pod
- Pod restart counts
- Node resource utilization

## Sample Dashboards

Import these dashboard IDs in Grafana:
- 16611 - Cilium Metrics
- 15760 - Kubernetes Cluster Monitoring

## Cleanup

No cleanup needed - monitoring stack remains running.
