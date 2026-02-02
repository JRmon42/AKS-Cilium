# Getting Started

Welcome! This guide will help you get started with the AKS Cilium demo repository.

## What You'll Build

By following this guide, you'll deploy:
- ✅ Azure Kubernetes Service (AKS) cluster with Cilium CNI
- ✅ Network policies for secure pod-to-pod communication
- ✅ Monitoring stack with Prometheus and Grafana
- ✅ OPA Gatekeeper for policy enforcement
- ✅ Sample applications to demonstrate capabilities

## Prerequisites

Before starting, you need:

### Required Tools
- **Azure CLI** (`az`) - [Install](https://docs.microsoft.com/cli/azure/install-azure-cli)
- **Terraform** (>= 1.5.0) - [Install](https://www.terraform.io/downloads)
- **kubectl** (>= 1.28) - [Install](https://kubernetes.io/docs/tasks/tools/)
- **Helm** (>= 3.12) - [Install](https://helm.sh/docs/intro/install/)
- **Cilium CLI** - [Install](https://docs.cilium.io/en/stable/gettingstarted/k8s-install-default/#install-the-cilium-cli)

### Azure Requirements
- Active Azure subscription
- Permissions to create resources
- Available quota for:
  - 3-5 virtual machines (Standard_D4s_v3)
  - 1 virtual network
  - 1 AKS cluster

### Quick Prerequisites Check

```bash
./scripts/check-prerequisites.sh
```

This will verify all required tools are installed.

## Quick Start (5 Minutes)

### 1. Clone the Repository

```bash
git clone https://github.com/JRmon42/AKS-Cilium.git
cd AKS-Cilium
```

### 2. Login to Azure

```bash
az login
az account set --subscription "<your-subscription-id>"
```

### 3. Deploy Everything

```bash
chmod +x scripts/deploy.sh
./scripts/deploy.sh
```

This single command will:
- ✅ Check prerequisites
- ✅ Initialize Terraform
- ✅ Deploy AKS with Cilium
- ✅ Install monitoring stack
- ✅ Install OPA Gatekeeper
- ✅ Configure kubectl
- ✅ Enable Hubble UI

**Deployment time**: ~15 minutes

### 4. Verify Deployment

```bash
# Check cluster
kubectl get nodes

# Check Cilium
cilium status

# Check monitoring
kubectl get pods -n monitoring

# Check Gatekeeper
kubectl get pods -n gatekeeper-system
```

## Run Your First Demo

### Network Policies Demo

```bash
cd demos/01-network-policies
chmod +x run-demo.sh
./run-demo.sh
```

This demo shows:
- Deploying a 3-tier application
- Blocking all traffic by default
- Allowing specific pod-to-pod communication
- Layer 7 HTTP policies
- FQDN-based egress control

### Visualize with Hubble

```bash
# Start Hubble UI
cilium hubble ui
```

Open http://localhost:12000 to see network flows in real-time!

## Explore Monitoring

### Access Grafana

```bash
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
```

Open http://localhost:3000
- **Username**: admin
- **Password**: admin

Import dashboard ID **16611** for Cilium metrics!

### Access Prometheus

```bash
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
```

Open http://localhost:9090

Try this query: `rate(cilium_drop_count_total[5m])`

## Test Policy Enforcement

### OPA Gatekeeper Demo

```bash
cd demos/03-constraints
chmod +x run-demo.sh
./run-demo.sh
```

This demo shows:
- Required labels enforcement
- Container registry restrictions
- Resource limits requirements
- Blocking privileged containers

### Try Creating a Non-Compliant Pod

```bash
# This should FAIL (missing labels)
kubectl run test --image=nginx -n demo-app

# This should SUCCEED
kubectl run test --image=nginx -n demo-app --labels="app=test,environment=demo"
```

## Understanding the Architecture

```
┌─────────────────────────────────────┐
│         AKS Cluster                  │
│  ┌──────────────────────────────┐   │
│  │   Application Layer          │   │
│  │  - Frontend                   │   │
│  │  - Backend                    │   │
│  │  - Database                   │   │
│  └──────────────────────────────┘   │
│           ↕ (Cilium Policies)       │
│  ┌──────────────────────────────┐   │
│  │   Platform Layer             │   │
│  │  - Cilium CNI                │   │
│  │  - Prometheus/Grafana        │   │
│  │  - OPA Gatekeeper            │   │
│  └──────────────────────────────┘   │
│           ↕                          │
│  ┌──────────────────────────────┐   │
│  │   Infrastructure Layer       │   │
│  │  - Kubernetes Nodes          │   │
│  │  - Azure Networking          │   │
│  └──────────────────────────────┘   │
└─────────────────────────────────────┘
```

## Repository Structure

```
.
├── terraform/              # Infrastructure as Code
│   ├── main.tf            # Main configuration
│   ├── variables.tf       # Input variables
│   └── outputs.tf         # Output values
├── manifests/             # Kubernetes manifests
│   ├── network-policies/  # Cilium network policies
│   ├── monitoring/        # Monitoring configs
│   └── constraints/       # OPA policies
├── demos/                 # Interactive demos
│   ├── 01-network-policies/
│   ├── 02-monitoring/
│   └── 03-constraints/
├── scripts/               # Utility scripts
└── docs/                  # Documentation
```

## Next Steps

Now that you have everything running:

### 1. Explore Network Policies
- Read [Network Policies README](../manifests/network-policies/README.md)
- Modify policies and observe effects
- Create your own policies

### 2. Set Up Custom Monitoring
- Import additional Grafana dashboards
- Create custom Prometheus alerts
- Explore Hubble observability

### 3. Configure Policy Enforcement
- Read [Constraints README](../manifests/constraints/README.md)
- Create custom OPA policies
- Test in dry-run mode first

### 4. Deploy Your Application
- Use demo apps as templates
- Apply network policies
- Monitor performance

### 5. Deep Dive into Documentation
- [Architecture Overview](ARCHITECTURE.md)
- [Deployment Guide](DEPLOYMENT.md)
- [Troubleshooting Guide](TROUBLESHOOTING.md)

## Common Tasks

### Scale the Cluster

```bash
cd terraform
# Edit terraform.tfvars: node_count = 5
terraform apply
```

### Update Kubernetes Version

```bash
# Check available versions
az aks get-versions --location eastus --output table

# Edit terraform/variables.tf: kubernetes_version = "1.29"
cd terraform
terraform apply
```

### Add a New Demo Application

```bash
# Create namespace
kubectl create namespace my-app

# Apply labels (required by Gatekeeper)
kubectl label namespace my-app environment=production

# Deploy your app with proper labels and resource limits
kubectl apply -f my-app.yaml -n my-app
```

### View Logs

```bash
# Cilium logs
kubectl logs -n kube-system -l k8s-app=cilium --tail=100

# Application logs
kubectl logs -n demo-app deployment/frontend -f

# Monitoring logs
kubectl logs -n monitoring -l app.kubernetes.io/name=prometheus
```

## Cleanup

When you're done:

```bash
# Quick cleanup
./scripts/cleanup.sh

# Or manual cleanup
cd terraform
terraform destroy -auto-approve
```

## Getting Help

- 📖 **Documentation**: Check the `docs/` folder
- 🐛 **Issues**: Report on GitHub Issues
- 💬 **Questions**: Start a GitHub Discussion
- 📧 **Support**: Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

## Tips for Success

1. **Start small**: Run demos before modifying
2. **Use dry-run**: Test policies in dry-run mode first
3. **Monitor costs**: Check Azure Cost Management regularly
4. **Save state**: Commit your terraform.tfvars (without secrets)
5. **Document changes**: Keep notes of customizations

## What's Different About This Setup?

- ✅ **Cilium instead of Azure CNI**: Better performance with eBPF
- ✅ **Network policies first**: Security by default
- ✅ **Policy enforcement**: OPA Gatekeeper prevents misconfigurations
- ✅ **Observable**: Hubble provides network visibility
- ✅ **Production-ready**: Monitoring, auto-scaling, HA

## Ready to Learn More?

- Try modifying network policies
- Create custom Gatekeeper constraints
- Set up alerting in Prometheus
- Deploy a real application
- Scale to production

Happy learning! 🚀
