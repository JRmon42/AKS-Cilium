# Azure Portal Management Guide

This guide provides instructions for managing your AKS cluster with Azure CNS and Cilium through the Azure Portal.

## 🌐 Accessing Your Cluster

1. Navigate to [Azure Portal](https://portal.azure.com)
2. Go to **Resource Groups** → `rg-aks-cilium-demo`
3. Click on your AKS cluster: `aks-cilium-demo`

## 📊 Monitoring & Insights

### Container Insights

**Navigate to:** AKS Cluster → Monitoring → Insights

**Key Features:**
- **Cluster Health**: Overall cluster status and resource utilization
- **Nodes**: CPU, memory, disk usage per node
- **Controllers**: Deployment, StatefulSet, DaemonSet status
- **Containers**: Individual container metrics and logs
- **Live Logs**: Real-time log streaming

**Useful Views:**
- **Performance**: CPU/Memory metrics with filtering
- **Health**: Status of cluster components
- **Metrics**: Prometheus-compatible metrics explorer

### Log Analytics

**Navigate to:** AKS Cluster → Monitoring → Logs

**Sample Queries:**

```kusto
// View Cilium agent logs
ContainerLog
| where ContainerName contains "cilium"
| project TimeGenerated, LogEntry, ContainerName
| order by TimeGenerated desc

// Pod restart analysis
KubePodInventory
| where PodStatus == "Running"
| summarize RestartCount=sum(PodRestartCount) by Name, Namespace
| where RestartCount > 0
| order by RestartCount desc

// Network policy denials (from Cilium)
ContainerLog
| where ContainerName contains "cilium"
| where LogEntry contains "Policy denied"
| project TimeGenerated, LogEntry
| order by TimeGenerated desc
```

## 🔒 Network Policy Management

### Viewing Network Policies

**Navigate to:** AKS Cluster → Kubernetes resources → Services and ingresses → Network Policies

**What You Can See:**
- All Kubernetes NetworkPolicy and CiliumNetworkPolicy resources
- Policy names, namespaces, and creation times
- Pod selectors and ingress/egress rules

**Note:** For detailed Cilium-specific policies, use kubectl or Hubble UI

### Service Mesh Insights

**Navigate to:** AKS Cluster → Kubernetes resources → Services and ingresses

**Available Information:**
- Service endpoints and external IPs
- Load balancer status
- Port mappings
- Service selectors

## 💻 Workload Management

### Viewing Workloads

**Navigate to:** AKS Cluster → Kubernetes resources → Workloads

**Available Resources:**
- **Deployments**: Application deployments and replica status
- **StatefulSets**: Stateful applications
- **DaemonSets**: Node-level services (including Cilium agents)
- **Pods**: Individual pod status and logs
- **ReplicaSets**: Replica management

**Actions You Can Perform:**
- Scale deployments up/down
- View pod logs
- Restart pods
- Update container images
- Review resource requests/limits

### Live Console

**Navigate to:** Pod → Connect

Execute commands directly in containers for debugging (requires RBAC permissions).

## ⚙️ Configuration

### Node Pool Management

**Navigate to:** AKS Cluster → Settings → Node pools

**Operations:**
- **Add node pools**: Create specialized node pools
- **Scale**: Adjust node count or enable autoscaling
- **Upgrade**: Update node OS or Kubernetes version
- **Configure**: Modify VM size, availability zones

**Current Configuration:**
- System node pool: 2-5 nodes (autoscaling enabled)
- VM Size: Standard_D4s_v3
- OS Disk: 128 GB Managed

### Networking Configuration

**Navigate to:** AKS Cluster → Settings → Networking

**Information Available:**
- **Network Profile**: Azure CNS overlay mode
- **Service CIDR**: 10.1.0.0/16
- **DNS Service IP**: 10.1.0.10
- **Load Balancer**: Standard SKU
- **Network Plugin**: Azure
- **Network Dataplane**: Cilium

**Note:** Network plugin cannot be changed after cluster creation.

### Kubernetes Version Management

**Navigate to:** AKS Cluster → Settings → Cluster configuration

**Available Actions:**
- **Upgrade cluster**: Update Kubernetes version
- **View available versions**: See supported K8s versions
- **Auto-upgrade channel**: Configure automatic updates (currently: stable)

## 🛡️ Security & Compliance

### Azure Policy

**Navigate to:** AKS Cluster → Security → Azure Policy

**Current Status:**
- Azure Policy enabled
- OPA Gatekeeper deployed (3 replicas)

**View:**
- Policy compliance status
- Non-compliant resources
- Audit results

### Managed Identity

**Navigate to:** AKS Cluster → Settings → Identity

**Configuration:**
- **Type**: User-assigned managed identity
- **Identity**: `id-aks-cilium-demo`
- **Permissions**: Network Contributor on AKS subnet

### Key Vault Integration

**Navigate to:** AKS Cluster → Settings → Secrets

**Features:**
- Secrets Provider enabled
- Secret rotation: Every 2 minutes
- Store secrets in Azure Key Vault

## 🔄 Upgrade & Maintenance

### Cluster Upgrades

**Navigate to:** AKS Cluster → Settings → Cluster configuration → Kubernetes version

**Best Practices:**
1. Review release notes before upgrading
2. Test in non-production first
3. Ensure applications are compatible
4. Monitor during upgrade window

**Automatic Upgrades:**
- Channel: Stable
- Maintenance window: Can be configured

### Node OS Updates

**Navigate to:** AKS Cluster → Settings → Node pools → [Select pool] → Node security

**Options:**
- **Unattended upgrades**: Automatic security updates
- **Image upgrades**: Update node OS image weekly/monthly
- **Kured**: Automatic node reboots for kernel updates

## 📈 Cost Management

### Cost Analysis

**Navigate to:** Resource Group → Cost Management → Cost analysis

**Analyze Costs By:**
- Resource (nodes, load balancers, disks)
- Service (AKS, Networking, Storage)
- Time range (daily, weekly, monthly)

**Cost Optimization Tips:**
- Enable autoscaling to match demand
- Use spot instances for non-critical workloads
- Right-size node VM SKUs
- Monitor and clean up unused resources

### Resource Metrics

**Navigate to:** AKS Cluster → Monitoring → Metrics

**Key Metrics to Monitor:**
- Node CPU/Memory utilization
- Pod count per node
- Disk IOPS and throughput
- Network bytes in/out

## 🔍 Troubleshooting via Portal

### Diagnose and Solve Problems

**Navigate to:** AKS Cluster → Diagnose and solve problems

**Available Diagnostics:**
- Cluster connectivity issues
- Node health problems
- Pod deployment failures
- Network policy conflicts
- Performance bottlenecks

### Activity Log

**Navigate to:** AKS Cluster → Activity log

**Useful For:**
- Tracking cluster changes
- Identifying who made changes
- Troubleshooting failed operations
- Compliance auditing

## 🚀 Advanced Features

### Workload Identity

**Navigate to:** AKS Cluster → Settings → Security → Workload Identity

**Status:** Enabled with OIDC issuer

**Use Case:** Pod authentication to Azure services without managing secrets

### GitOps with Flux

**Navigate to:** AKS Cluster → GitOps

**Configure:**
- Connect Git repository
- Deploy applications declaratively
- Continuous reconciliation

## 📚 Additional Portal Resources

### Resource Links

- **Cluster Dashboard**: Overview of all cluster resources
- **Advisor Recommendations**: Security and performance suggestions
- **Service Health**: Azure service status and incidents
- **Support + Troubleshooting**: Create support requests

## 🔗 Related CLI Commands

While the Portal provides extensive GUI capabilities, some operations are still best performed via CLI:

```bash
# Get cluster credentials
az aks get-credentials --resource-group rg-aks-cilium-demo --name aks-cilium-demo

# Check Cilium status (requires Cilium CLI)
cilium status

# View Hubble flows (network observability)
cilium hubble ui

# Port-forward to Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
```

## 💡 Tips for Effective Portal Management

1. **Bookmarks**: Save frequently used portal views
2. **Dashboards**: Create custom dashboards for your cluster
3. **Alerts**: Configure metric alerts for proactive monitoring
4. **Tags**: Use tags for cost allocation and organization
5. **Resource Graph**: Use Azure Resource Graph for complex queries
6. **mobile App**: Download Azure mobile app for on-the-go management

---

For advanced networking features and Cilium-specific capabilities, combine Portal management with Hubble UI and Cilium CLI tools.
