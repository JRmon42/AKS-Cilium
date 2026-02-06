# AKS with Cilium - Network Policy, Monitoring, and Constraints Demo

This repository contains Infrastructure as Code (IaaC) to deploy an Azure Kubernetes Service (AKS) cluster with **Azure CNS (Container Networking Service)** and Cilium dataplane for demonstrating:
- **Network Policies** with Cilium
- **Monitoring** with Azure Monitor, Prometheus, and Grafana
- **Policy Constraints** with OPA Gatekeeper

## 🏗️ Architecture Overview

The deployment includes:
- AKS cluster with **Azure CNS (Container Networking Service) in overlay mode**
- **Cilium as the eBPF dataplane** for advanced networking capabilities
- Azure Monitor for container insights
- Prometheus & Grafana for metrics
- OPA Gatekeeper for policy enforcement
- Sample applications for demo scenarios
- **Azure Portal integration** for GUI-based management

## 📋 Prerequisites

- Azure CLI (`az`) installed and configured
- Terraform >= 1.5.0
- kubectl >= 1.28
- Helm >= 3.12
- An active Azure subscription

## 🚀 Quick Start

### 1. Deploy Infrastructure

```bash
cd terraform
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

### 2. Configure kubectl

```bash
az aks get-credentials --resource-group rg-aks-cilium-demo --name aks-cilium-demo
```

### 3. Verify Cilium Installation

```bash
kubectl get pods -n kube-system | grep cilium
cilium status --wait
```

### 4. View in Azure Portal

You can also manage and monitor your AKS cluster using the Azure Portal:

1. Navigate to [Azure Portal](https://portal.azure.com)
2. Go to **Resource Groups** > `rg-aks-cilium-demo`
3. Click on the AKS cluster: `aks-cilium-demo`

**Portal Features:**
- **Workloads**: View pods, deployments, services
- **Networking**: Monitor network policies, services, ingresses
- **Monitoring**: Container Insights, metrics, logs
- **Security**: Azure Policy compliance, security posture
- **Configuration**: Scale node pools, update settings

### 5. Run Demos

```bash
# Network Policy Demo
./demos/01-network-policies/run-demo.sh

# Monitoring Demo
./demos/02-monitoring/run-demo.sh

# Constraints Demo
./demos/03-constraints/run-demo.sh
```

## 🚀 Access Management UIs

### Quick Start All UIs

```bash
# Start all monitoring and observability UIs at once
chmod +x scripts/open-all-uis.sh
./scripts/open-all-uis.sh
```

This will start:
- **Grafana** at http://localhost:3000 (admin/prom-operator)
- **Hubble UI** at http://localhost:12000
- **Prometheus** at http://localhost:9090
- **AlertManager** at http://localhost:9093

**See [Quick Access Guide](docs/QUICK-ACCESS.md) for detailed instructions.**

## 📁 Repository Structure

```
.
├── terraform/              # Terraform IaaC files
│   ├── main.tf            # Main configuration (Azure CNS + Cilium)
│   ├── variables.tf       # Input variables
│   ├── outputs.tf         # Output values + Portal URLs
│   └── versions.tf        # Provider versions
├── docs/                  # Documentation
│   ├── ARCHITECTURE.md    # Architecture overview
│   ├── DEPLOYMENT.md      # Deployment guide
│   ├── GETTING-STARTED.md # Getting started guide
│   ├── TROUBLESHOOTING.md # Troubleshooting tips
│   ├── AZURE-CNS.md       # Azure CNS detailed documentation
│   ├── PORTAL-GUIDE.md    # Azure Portal management guide
│   └── QUICK-ACCESS.md    # Quick reference for all UIs
├── manifests/             # Kubernetes manifests
│   ├── network-policies/  # Network policy examples
│   ├── monitoring/        # Monitoring stack
│   └── constraints/       # OPA Gatekeeper policies
├── demos/                 # Demo scenarios
│   ├── 01-network-policies/
│   ├── 02-monitoring/
│   └── 03-constraints/
└── scripts/               # Utility scripts
    ├── deploy.sh          # Main deployment script
    ├── cleanup.sh         # Cleanup script
    ├── check-prerequisites.sh
    └── open-all-uis.sh    # Start all monitoring UIs
```

## 🌐 Azure CNS with Cilium

This deployment uses **Azure Container Networking Service (CNS) in overlay mode** with Cilium as the dataplane:

**Benefits:**
- **Scalability**: Overlay network decouples pod IPs from VNet IP space
- **Flexibility**: No subnet IP exhaustion concerns
- **Performance**: Cilium eBPF dataplane for high-performance networking
- **Advanced Features**: L7 policies, DNS filtering, network observability

**Network Configuration:**
- Network Plugin: `azure`
- Plugin Mode: `overlay`
- Dataplane: `cilium`
- Pod CIDR: Managed by Azure CNS
- Service CIDR: `10.1.0.0/16`

## 🔒 Network Policies Demo

Demonstrates:
- Default deny all traffic
- Allow specific ingress/egress
- Layer 7 policies with Cilium
- DNS-based policies
- FQDN-based filtering

## 📊 Monitoring Demo

Includes:
- **Azure Portal**: Container Insights, metrics explorer, log queries
- **Azure Monitor**: Container health, performance metrics
- **Prometheus**: Kubernetes and Cilium metrics collection
- **Grafana**: Custom dashboards and visualizations
- **Cilium Hubble**: Network flow observability and service map

### Access Monitoring Tools:

**Azure Portal:**
- Go to AKS cluster → Monitoring → Insights
- View container logs, metrics, and live data

**Grafana:**
```bash
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
```
Access at http://localhost:3000 (admin/prom-operator)

**Hubble UI:**
```bash
cilium hubble ui
```
Access at http://localhost:12000

## 🛡️ Constraints Demo

Shows:
- Required labels enforcement
- Image registry restrictions
- Resource limits requirements
- Security context validation

## 🧹 Cleanup

```bash
cd terraform
terraform destroy -auto-approve
```

## 📚 Additional Resources

### Project Documentation
- [Azure CNS with Cilium Guide](docs/AZURE-CNS.md) - Detailed Azure CNS networking documentation
- [Azure Portal Management Guide](docs/PORTAL-GUIDE.md) - Comprehensive GUI management guide
- [Quick Access Guide](docs/QUICK-ACCESS.md) - Quick reference for accessing all UIs
- [Architecture Overview](docs/ARCHITECTURE.md) - System architecture details
- [Deployment Guide](docs/DEPLOYMENT.md) - Step-by-step deployment
- [Troubleshooting Guide](docs/TROUBLESHOOTING.md) - Common issues and solutions

### External Resources
- [AKS Documentation](https://learn.microsoft.com/en-us/azure/aks/)
- [Azure CNS Overview](https://learn.microsoft.com/en-us/azure/aks/azure-cni-overlay)
- [Cilium on AKS](https://learn.microsoft.com/en-us/azure/aks/use-cilium-dataplane)
- [Cilium Documentation](https://docs.cilium.io/)
- [Hubble Observability](https://docs.cilium.io/en/stable/gettingstarted/hubble/)
- [OPA Gatekeeper](https://open-policy-agent.github.io/gatekeeper/)

## 🤝 Contributing

Feel free to submit issues and enhancement requests!

## 📝 License

MIT License
# AKS-Cilium
