# AKS with Cilium - Network Policy, Monitoring, and Constraints Demo

This repository contains Infrastructure as Code (IaaC) to deploy an Azure Kubernetes Service (AKS) cluster with Cilium for demonstrating:
- **Network Policies** with Cilium
- **Monitoring** with Azure Monitor, Prometheus, and Grafana
- **Policy Constraints** with OPA Gatekeeper

## 🏗️ Architecture Overview

The deployment includes:
- AKS cluster with Cilium CNI
- Azure Monitor for container insights
- Prometheus & Grafana for metrics
- OPA Gatekeeper for policy enforcement
- Sample applications for demo scenarios

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

### 4. Run Demos

```bash
# Network Policy Demo
./demos/01-network-policies/run-demo.sh

# Monitoring Demo
./demos/02-monitoring/run-demo.sh

# Constraints Demo
./demos/03-constraints/run-demo.sh
```

## 📁 Repository Structure

```
.
├── terraform/              # Terraform IaaC files
│   ├── main.tf            # Main configuration
│   ├── variables.tf       # Input variables
│   ├── outputs.tf         # Output values
│   └── versions.tf        # Provider versions
├── bicep/                 # Alternative Bicep deployment
│   └── main.bicep         # Main Bicep file
├── manifests/             # Kubernetes manifests
│   ├── network-policies/  # Network policy examples
│   ├── monitoring/        # Monitoring stack
│   └── constraints/       # OPA Gatekeeper policies
├── demos/                 # Demo scenarios
│   ├── 01-network-policies/
│   ├── 02-monitoring/
│   └── 03-constraints/
└── scripts/               # Utility scripts
```

## 🔒 Network Policies Demo

Demonstrates:
- Default deny all traffic
- Allow specific ingress/egress
- Layer 7 policies with Cilium
- DNS-based policies

## 📊 Monitoring Demo

Includes:
- Azure Monitor Container Insights
- Prometheus metrics collection
- Grafana dashboards
- Cilium Hubble observability

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

- [AKS Documentation](https://learn.microsoft.com/en-us/azure/aks/)
- [Cilium Documentation](https://docs.cilium.io/)
- [OPA Gatekeeper](https://open-policy-agent.github.io/gatekeeper/)

## 🤝 Contributing

Feel free to submit issues and enhancement requests!

## 📝 License

MIT License
