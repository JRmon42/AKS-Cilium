# Deployment Guide

This guide provides step-by-step instructions for deploying the AKS cluster with Cilium.

## Prerequisites

Before you begin, ensure you have:

1. **Azure Subscription**: An active Azure subscription
2. **Tools Installed**:
   - Azure CLI (`az`)
   - Terraform (>= 1.5.0)
   - kubectl (>= 1.28)
   - Helm (>= 3.12)
   - Cilium CLI

Run the prerequisites check script:
```bash
./scripts/check-prerequisites.sh
```

## Quick Deployment

### Automated Deployment

The easiest way to deploy everything:

```bash
./scripts/deploy.sh
```

This script will:
1. Check prerequisites
2. Verify Azure login
3. Initialize Terraform
4. Deploy the AKS cluster with Cilium
5. Install Prometheus & Grafana
6. Install OPA Gatekeeper
7. Enable Hubble UI
8. Configure kubectl

### Manual Deployment

If you prefer manual deployment:

#### 1. Login to Azure

```bash
az login
az account set --subscription "<subscription-id>"
```

#### 2. Configure Terraform Variables

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` and customize values:
- `location`: Azure region (default: eastus)
- `cluster_name`: AKS cluster name
- `node_count`: Number of nodes
- `node_vm_size`: VM size for nodes

#### 3. Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Preview changes
terraform plan -out=tfplan

# Apply changes
terraform apply tfplan
```

This will take approximately 10-15 minutes.

#### 4. Configure kubectl

```bash
az aks get-credentials \
  --resource-group rg-aks-cilium-demo \
  --name aks-cilium-demo
```

#### 5. Verify Deployment

```bash
# Check cluster
kubectl get nodes

# Check Cilium
kubectl get pods -n kube-system | grep cilium
cilium status

# Check monitoring
kubectl get pods -n monitoring

# Check Gatekeeper
kubectl get pods -n gatekeeper-system
```

#### 6. Enable Hubble UI

```bash
cilium hubble enable --ui
```

## Post-Deployment Configuration

### 1. Access Grafana

```bash
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
```

Open http://localhost:3000
- Username: `admin`
- Password: `admin` (change on first login)

Import dashboards:
- Cilium Dashboard: ID 16611
- Kubernetes Dashboard: ID 15760

### 2. Access Prometheus

```bash
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
```

Open http://localhost:9090

### 3. Access Hubble UI

```bash
cilium hubble ui
```

Open http://localhost:12000

### 4. Configure Azure Monitor

Azure Monitor Container Insights is automatically configured. Access it via:

```bash
az aks show \
  --resource-group rg-aks-cilium-demo \
  --name aks-cilium-demo \
  --query id -o tsv
```

Then navigate to Azure Portal → AKS → Insights

## Running Demos

### Network Policies Demo

```bash
cd demos/01-network-policies
chmod +x run-demo.sh
./run-demo.sh
```

### Monitoring Demo

```bash
cd demos/02-monitoring
chmod +x run-demo.sh
./run-demo.sh
```

### OPA Gatekeeper Constraints Demo

```bash
cd demos/03-constraints
chmod +x run-demo.sh
./run-demo.sh
```

## Customization

### Modify Node Count

Edit `terraform/terraform.tfvars`:
```hcl
node_count = 5  # Change from 3 to 5
```

Apply changes:
```bash
cd terraform
terraform apply
```

### Add Node Pool

Edit `terraform/main.tf` and add:
```hcl
resource "azurerm_kubernetes_cluster_node_pool" "user" {
  name                  = "user"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  vm_size              = "Standard_D4s_v3"
  node_count           = 3
  
  tags = var.tags
}
```

### Change Region

**Warning**: Changing regions requires recreating resources.

Edit `terraform/terraform.tfvars`:
```hcl
location = "westus2"  # Change region
```

## Troubleshooting

### Cilium Not Ready

```bash
# Check Cilium status
cilium status

# Check Cilium pods
kubectl get pods -n kube-system -l k8s-app=cilium

# View Cilium logs
kubectl logs -n kube-system -l k8s-app=cilium
```

### Terraform Issues

```bash
# Re-initialize
terraform init -upgrade

# Destroy and recreate
terraform destroy
terraform apply
```

### Monitoring Stack Issues

```bash
# Check Prometheus
kubectl get pods -n monitoring -l app.kubernetes.io/name=prometheus

# Check Grafana
kubectl get pods -n monitoring -l app.kubernetes.io/name=grafana

# Reinstall Prometheus stack
helm uninstall prometheus -n monitoring
# Then re-run terraform apply
```

### Gatekeeper Issues

```bash
# Check Gatekeeper status
kubectl get pods -n gatekeeper-system

# View audit logs
kubectl logs -n gatekeeper-system -l control-plane=audit-controller

# Reinstall Gatekeeper
helm uninstall gatekeeper -n gatekeeper-system
# Then re-run terraform apply
```

## Cleanup

### Quick Cleanup

```bash
./scripts/cleanup.sh
```

### Manual Cleanup

```bash
cd terraform
terraform destroy -auto-approve
```

This will remove:
- AKS cluster
- Virtual network
- Log Analytics workspace
- All associated resources

**Note**: Persistent volumes and other manually created resources may need separate cleanup.

## Cost Optimization

### Development/Testing

For cost savings during development:

```hcl
# terraform/terraform.tfvars
node_vm_size = "Standard_B2s"
node_count = 1
enable_auto_scaling = false
```

### Stop Cluster (Not Supported for Production)

AKS doesn't support stopping clusters, but you can:
1. Scale down node pools to 0
2. Destroy and recreate when needed

```bash
az aks nodepool scale \
  --resource-group rg-aks-cilium-demo \
  --cluster-name aks-cilium-demo \
  --name system \
  --node-count 0
```

## Next Steps

After deployment:

1. ✅ Run all demos to familiarize yourself
2. ✅ Explore monitoring dashboards
3. ✅ Test network policies
4. ✅ Review OPA Gatekeeper constraints
5. ✅ Customize for your needs
6. ✅ Deploy your applications

## Support

For issues or questions:
- Check the [README.md](../README.md)
- Review individual component READMEs
- Check Azure AKS documentation
- Check Cilium documentation
