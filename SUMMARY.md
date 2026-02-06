# Repository Summary

**AKS with Azure CNS and Cilium - Network Policy, Monitoring, and Constraints Demo**

## 📦 What's Included

This repository is now a **complete, production-ready Infrastructure as Code solution** for deploying Azure Kubernetes Service with **Azure CNS (Container Networking Service)** and **Cilium dataplane**, including:

### Infrastructure (Terraform)
✅ AKS cluster with **Azure CNS overlay networking**  
✅ **Cilium eBPF dataplane** for advanced networking  
✅ Virtual network and subnet configuration  
✅ Log Analytics workspace integration  
✅ Managed identity setup  
✅ Auto-scaling configuration  
✅ Azure Monitor integration  
✅ **Azure Portal integration** with direct URLs  

### Monitoring Stack
✅ Prometheus with Cilium metrics scraping  
✅ Grafana with pre-configured dashboards  
✅ AlertManager for notifications  
✅ Hubble for network observability  
✅ Azure Monitor Container Insights  

### Security & Policy
✅ Cilium network policies (L3-L7)  
✅ OPA Gatekeeper with 4 constraint templates  
✅ Sample constraints for enforcement  
✅ Network segmentation examples  
✅ FQDN-based egress control  

### Demo Applications
✅ 3-tier sample application  
✅ Network policies demo  
✅ Monitoring demo  
✅ Constraints demo  
✅ Interactive scripts for each demo  

### Documentation
✅ Comprehensive README  
✅ **Azure CNS with Cilium guide**  
✅ **Azure Portal management guide**  
✅ **Quick access guide for all UIs**  
✅ Getting Started guide  
✅ Architecture documentation  
✅ Deployment guide  
✅ Troubleshooting guide  
✅ Contributing guidelines  

### Automation Scripts
✅ Deployment a  
✅ **One-click UI launcher** (Grafana, Hubble, Prometheus)utomation  
✅ Prerequisites checker  
✅ Cleanup script  
✅ Demo runners  

## 📁 Complete File Structure

```
AKS-Cilium/
├── README.md                          # Main documentation
├── LICENSE                            # MIT license
├── CONTRIBUTING.md                    # Contribution guidelines
├── .gitignore                         # Git ignore rules
│
├── terraform/                         # Infrastructure as Code
│   ├── main.tf                       # Main AKS + Cilium config
│   ├── variables.tf                  # Input variables
│   ├── outputs.tf                    # Output values
│   ├── versions.tf                   # Provider versions
│   ├── terraform.tfvars.example      # Example configuration
│   └── helm-values/
│       └── prometheus-values.yaml    # Prometheus configuration
│
├── manifests/                         # Kubernetes manifests
│   ├── network-policies/             # Cilium network policies
│   │   ├── README.md                 # Policy documentation
│   │   ├── 00-namespace.yaml         # Demo namespace
│   │   ├── 01-sample-apps.yaml       # 3-tier application
│   │   ├── 02-default-deny.yaml      # Default deny policy
│   │   ├── 03-allow-specific-traffic.yaml
│   │   ├── 04-allow-dns.yaml         # DNS resolution
│   │   ├── 05-l7-policy.yaml         # Layer 7 HTTP policy
│   │   └── 06-fqdn-policy.yaml       # FQDN egress policy
│   │
│   ├── monitoring/                    # Monitoring stack
│   │   ├── README.md                 # Monitoring documentation
│   │   ├── grafana-dashboards.yaml   # Dashboard configs
│   │   ├── prometheus-config.yaml    # Additional Prometheus config
│   │   └── servicemonitors.yaml      # Cilium service monitors
│   │
│   └── constraints/                   # OPA Gatekeeper policies
│       ├── README.md                 # Policy documentation
│       ├── templates/                # Constraint templates
│       │   ├── required-labels.yaml
│       │   ├── allowed-repos.yaml
│       │   ├── container-limits.yaml
│       │   └── block-privileged.yaml
│       └── constraints/              # Constraint instances
│           ├── require-labels.yaml
│           ├── allowed-repos.yaml
│           ├── require-limits.yaml
│           └── block-privileged.yaml
│
├── demos/                             # Interactive demonstrations
│   ├── 01-network-policies/
│   │   ├── README.md
│   │   └── run-demo.sh              # Automated demo script
│   ├── 02-monitoring/
│   │   ├── README.md
│   │   └── run-demo.sh              # Monitoring demo
│   └── 03-constraints/
│       ├── README.md
│       └── run-demo.sh              # Policy enforcement demo
│
├── scripts/                           # Utility scripts
│   ├── deploy.sh                     # Full deployment automation
│   ├── check-prerequisites.sh        # Prerequisites verification
│   └── open-all-uis.sh              # Start all monitoring UIs
│
└── docs/                              # Additional documentation
    ├── GETTING-STARTED.md            # Quick start guide
    ├── ARCHITECTURE.md               # Architecture details
    ├── DEPLOYMENT.md                 # Deployment guide
    ├── TROUBLESHOOTING.md            # Troubleshooting guide
    ├── AZURE-CNS.md                  # Azure CNS networking guide
    ├── PORTAL-GUIDE.md               # Azure Portal management
    └── QUICK-ACCESS.md               # Quick reference for UIs
    └── TROUBLESHOOTING.md            # Troubleshooting guide
```

## 🚀 Quick Start Commands

```bash
# Clone and enter repository
git clone https://github.com/JRmon42/AKS-Cilium.git
cd AKS-Cilium

# Check prerequisites
./scripts/check-prerequisites.sh

# Deploy everything
./scripts/deploy.sh

# Run demos
./demos/01-network-policies/run-demo.sh
./demos/02-monitoring/run-demo.sh
./demos/03-constraints/run-demo.sh

# Cleanup
./scripts/cleanup.sh
```Azure CNS**: Container Networking Service with overlay networking (no IP exhaustion)
2. **Cilium eBPF**: High-performance dataplane with kernel-level packet processing
3. **Network Policies**: L3-L7 policies with DNS and FQDN support
4. **Observability**: Hubble UI for real-time network flow visualization
5. **Monitoring**: Complete Prometheus/Grafana stack with Azure Monitor
6. **Portal Integration**: Full Azure Portal GUI management support
7. **Policy Enforcement**: OPA Gatekeeper with custom constraints
8. **Network Policies**: L3-L7 policies with DNS and FQDN support
3. **Observability**: Hubble UI for real-time network flow visualization
4. **Monitoring**: Complete Prometheus/Grafana stack
5. **Policy Enforcement**: OPA Gatekeeper with custom constraints
6. **Production-Ready**: Auto-scaling, HA, monitoring, security

## 📊 What You Can Demo

### Network Policies
- Default deny all traffic
- Selective allow between tiers
- Layer 7 HTTP method filtering
- FQDN-based egress control
- DNS policy management

### Monitoring
- Cilium metrics in Prometheus
- Custom Grafana dashboards
- Network flow visualization with Hubble
- Azure Monitor integration
- Real-time alerting

### Policy Enforcement
- Required labels on resources
- Container registry restrictions
- Resource limits enforcement
- Privileged container blocking
- Dry-run mode testing

## 🎯 Use Cases

- **Learning**: Understand AKS, Cilium, and cloud-native security
- **Demos**: Show network policies and observability
- **PoC**: Proof of concept for Cilium adoption
- **Template**: Starting point for production deployments
- **Training**: Hands-on Kubernetes security training

## 📝 Next Steps

1. ⭐ **Star this repo** if you find it useful
2. 🍴 **Fork it** to customize for your needs
3. 🐛 **Report issues** you encounter
4. 💬 **Share feedback** on what's useful
5. 🤝 **Contribute** improvements

## 🔗 Resources

- Repository: https://github.com/JRmon42/AKS-Cilium
- AKS Docs: https://learn.microsoft.com/azure/aks/
- Cilium Docs: https://docs.cilium.io/
- Gatekeeper: https://open-policy-agent.github.io/gatekeeper/

---

**Ready to deploy?** Start with `docs/GETTING-STARTED.md`

**Questions?** Check `docs/TROUBLESHOOTING.md`

**Want to contribute?** Read `CONTRIBUTING.md`
