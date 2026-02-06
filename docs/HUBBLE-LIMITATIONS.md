# Hubble Limitations with AKS-Managed Cilium

## Issue

When using **AKS-managed Cilium** (Azure CNI with Cilium dataplane), Hubble observability features are **disabled by default and cannot be enabled** by users.

### Why?

Azure manages the Cilium configuration in AKS clusters. The `enable-hubble` setting is controlled by Azure and is set to `false`. Any manual changes to the ConfigMap are reverted automatically.

## What Doesn't Work

❌ **Hubble UI** - Cannot visualize service maps and flow graphs  
❌ **Hubble Observe CLI** - Cannot view real-time network flows  
❌ **Hubble Relay** - Cannot aggregate flows from multiple Cilium agents  

## What DOES Work

✅ **Cilium Metrics** - Available via Prometheus  
✅ **Network Policies** - Fully functional (L3-L7)  
✅ **Grafana Dashboards** - Complete monitoring solution  
✅ **Azure Monitor** - Container Insights and metrics  
✅ **kubectl commands** - View policies, endpoints, identities  

## Alternative Monitoring Solutions

### 1. Use Grafana (Recommended)

Access Grafana to view Cilium metrics:

```bash
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
```

Open http://localhost:3000 (admin/prom-operator)

**Available Dashboards:**
- Cilium Agent Metrics
- Network Policy Drop Counts  
- DNS metrics
- HTTP/TCP flow metrics
- Drop reasons and verdicts

### 2. Use Prometheus Queries

Access Prometheus directly:

```bash
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
```

**Useful Queries:**

```promql
# Network policy drops
sum(rate(cilium_drop_count_total{reason="Policy denied"}[5m])) by (reason, direction)

# DNS queries
rate(cilium_forward_count_total{direction="EGRESS",protocol="UDP",port="53"}[5m])

# HTTP requests
rate(cilium_forward_count_total{protocol="TCP",port="80"}[5m])

# Policy enforcement events  
cilium_policy_endpoint_enforcement_status
```

### 3. Use Azure Monitor Container Insights

1. Go to [Azure Portal](https://portal.azure.com)
2. Navigate to your AKS cluster
3. Go to **Monitoring** → **Insights**

**Features:**
- Container logs and metrics
- Workload-level metrics
- Network performance metrics
- Custom log queries

### 4. Check Network Policies via kubectl

```bash
# View Cilium network policies  
kubectl get ciliumnetworkpolicies --all-namespaces

# Describe a specific policy
kubectl describe cnp <policy-name> -n <namespace>

# View Cilium endpoints
kubectl get cep --all-namespaces

# Get Cilium identities
kubectl get ciliumidentities
```

### 5. Use Cilium Agent Commands

Exec into a Cilium agent pod to check status:

```bash
# Get Cilium agent logs
kubectl logs -n kube-system ds/cilium -c cilium-agent --tail=50

# Check policy enforcement
CILIUM_POD=$(kubectl get pods -n kube-system -l k8s-app=cilium -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n kube-system $CILIUM_POD -- cilium policy get

# View endpoint list
kubectl exec -n kube-system $CILIUM_POD -- cilium endpoint list

# Check BPF maps
kubectl exec -n kube-system $CILIUM_POD -- cilium bpf policy list
```

## If You Need Full Hubble

If full Hubble observability is critical for your use case, you have these options:

### Option 1: Use AKS with BYO CNI (Bring Your Own CNI)

Deploy AKS with no network plugin, then install Cilium yourself via Helm:

```hcl
# Terraform example
resource "azurerm_kubernetes_cluster" "aks" {
  network_profile {
    network_plugin = "none"  # BYO CNI
  }
}
```

Then install Cilium with Hubble enabled:

```bash
helm install cilium cilium/cilium \
  --namespace kube-system \
  --set hubble.enabled=true \
  --set hubble.relay.enabled=true \
  --set hubble.ui.enabled=true
```

**Trade-offs:**
- ⚠️ You manage Cilium upgrades and configuration
- ⚠️ No Azure support for Cilium issues
- ⚠️ More operational overhead
- ✅ Full control over Hubble and all Cilium features

### Option 2: Deploy to Non-AKS Kubernetes

Use a self-managed Kubernetes cluster where you control the CNI:

- Azure VMs with kubeadm
- Azure Kubernetes Service (AKS) Engine  
- Other cloud providers
- On-premises clusters

## Workaround: Network Policy Testing

To validate network policies work correctly without Hubble UI:

```bash
# Test connectivity between pods
kubectl exec -n demo-app deployment/frontend -- wget -O- --timeout=5 http://backend:5678

# Check if policy blocked connection (should timeout)  
kubectl exec -n demo-app deployment/frontend -- timeout 3 nc -zv database 5432

# Generate traffic and check metrics in Grafana
watch -n 2 'kubectl exec -n demo-app deployment/frontend -- wget -qO- http://backend:5678'
```

## Summary

| Feature | AKS-Managed Cilium | BYO Cilium |
|---------|-------------------|------------|
| Network Policies (L3/L4) | ✅ Yes | ✅ Yes |
| L7 Policies | ✅ Yes | ✅ Yes |
| Cilium Metrics | ✅ Yes | ✅ Yes |
| Hubble UI | ❌ No | ✅ Yes |
| Hubble Observe | ❌ No | ✅ Yes | 
| Azure Support | ✅ Yes | ❌ No |
| Azure-managed upgrades | ✅ Yes | ❌ No |

## Recommendation

For this demo and most production scenarios:

**Use Grafana + Prometheus for monitoring** - provides comprehensive metrics without needing Hubble UI.

The combination of:
- Grafana dashboards
- Prometheus metrics
- Azure Monitor Container Insights  
- kubectl commands
- Network policy testing

...provides excellent observability for Cilium on AKS without requiring Hubble UI.

---

**Learn more:**
- [Azure CNI with Cilium](https://learn.microsoft.com/en-us/azure/aks/azure-cni-powered-by-cilium)
- [Cilium Metrics](https://docs.cilium.io/en/stable/observability/metrics/)
- [Monitoring Guide](PORTAL-GUIDE.md#monitoring--insights)
