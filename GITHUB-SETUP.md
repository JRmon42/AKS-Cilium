# Git initialization and GitHub setup

## Initialize Git Repository

```bash
cd c:\Users\jpontvianne\Documents\Azure\AKS-Cilium

# Initialize git
git init

# Add all files
git add .

# Initial commit
git commit -m "Initial commit: AKS with Cilium - Network Policy, Monitoring, and Constraints Demo

Complete IaC solution including:
- Terraform configuration for AKS with Cilium
- Network policy examples (L3-L7)
- Monitoring stack (Prometheus, Grafana, Hubble)
- OPA Gatekeeper constraints
- Interactive demo scripts
- Comprehensive documentation
"
```

## Create GitHub Repository

### Option 1: Using GitHub CLI (gh)

```bash
# Install GitHub CLI if needed
# Windows: winget install GitHub.cli
# Mac: brew install gh

# Login
gh auth login

# Create repository
gh repo create JRmon42/AKS-Cilium --public --source=. --remote=origin --push

# Description
gh repo edit JRmon42/AKS-Cilium --description "Azure Kubernetes Service with Cilium CNI - Demo for Network Policies, Monitoring, and OPA Gatekeeper Constraints"

# Add topics
gh repo edit JRmon42/AKS-Cilium --add-topic azure,kubernetes,aks,cilium,network-policies,monitoring,opa-gatekeeper,terraform,infrastructure-as-code
```

### Option 2: Manual GitHub Setup

1. **Go to GitHub**: https://github.com/new
2. **Repository name**: `AKS-Cilium`
3. **Description**: `Azure Kubernetes Service with Cilium CNI - Demo for Network Policies, Monitoring, and OPA Gatekeeper Constraints`
4. **Visibility**: Public
5. **Do NOT initialize** with README, .gitignore, or license (we already have them)
6. Click **"Create repository"**

Then push your code:

```bash
git remote add origin https://github.com/JRmon42/AKS-Cilium.git
git branch -M main
git push -u origin main
```

## Configure Repository Settings

### Topics/Tags
Add these topics to your repository:
- `azure`
- `kubernetes`
- `aks`
- `cilium`
- `network-policies`
- `monitoring`
- `opa-gatekeeper`
- `terraform`
- `infrastructure-as-code`
- `ebpf`
- `hubble`
- `prometheus`
- `grafana`
- `demo`

### GitHub Pages (Optional)
Enable GitHub Pages for documentation:
1. Go to Settings → Pages
2. Source: Deploy from branch
3. Branch: main, folder: /docs
4. Save

### Branch Protection (Recommended)
1. Go to Settings → Branches
2. Add rule for `main` branch
3. Check:
   - Require pull request reviews before merging
   - Require status checks to pass before merging
   - Require branches to be up to date before merging

### GitHub Actions Secrets (for CI/CD)
Add these secrets for GitHub Actions:
1. Go to Settings → Secrets and variables → Actions
2. Add:
   - `AZURE_CLIENT_ID`
   - `AZURE_TENANT_ID`
   - `AZURE_SUBSCRIPTION_ID`

## Repository Features to Enable

- ✅ Issues
- ✅ Pull Requests
- ✅ Discussions (for Q&A)
- ✅ Projects (optional)
- ✅ Wiki (optional)
- ✅ Actions (for CI/CD)

## Create Release (After First Deployment)

```bash
# Tag the release
git tag -a v1.0.0 -m "Initial release: Complete AKS-Cilium demo

Features:
- AKS cluster with Cilium CNI
- Network policies (L3-L7)
- Monitoring stack
- OPA Gatekeeper
- Interactive demos
- Full documentation
"

# Push tag
git push origin v1.0.0

# Create release on GitHub
gh release create v1.0.0 \
  --title "v1.0.0 - Initial Release" \
  --notes "Complete Infrastructure as Code solution for AKS with Cilium

## Features
- ✅ Terraform configuration for AKS with Cilium
- ✅ Network policies (L3-L7) with examples
- ✅ Monitoring stack (Prometheus, Grafana, Hubble)
- ✅ OPA Gatekeeper constraints
- ✅ Interactive demo scripts
- ✅ Comprehensive documentation

## Quick Start
\`\`\`bash
git clone https://github.com/JRmon42/AKS-Cilium.git
cd AKS-Cilium
./scripts/deploy.sh
\`\`\`

See [GETTING-STARTED.md](docs/GETTING-STARTED.md) for details."
```

## Repository README Badge Ideas

Add these to your main README.md:

```markdown
[![Terraform](https://img.shields.io/badge/Terraform-1.5+-623CE4?logo=terraform)](https://www.terraform.io/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.28+-326CE5?logo=kubernetes)](https://kubernetes.io/)
[![Cilium](https://img.shields.io/badge/Cilium-Latest-F8C517?logo=cilium)](https://cilium.io/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)
```

## Post-Publish Checklist

- [ ] Repository created on GitHub
- [ ] All files pushed to main branch
- [ ] Topics/tags added
- [ ] Repository description set
- [ ] README renders correctly
- [ ] Links in documentation work
- [ ] GitHub Actions workflows valid (if secrets configured)
- [ ] License file present
- [ ] Contributing guidelines available
- [ ] Initial release created (optional)
- [ ] Social media announcement (optional)

## Maintenance

### Keep Dependencies Updated

Create a `.github/dependabot.yml`:
```yaml
version: 2
updates:
  - package-ecosystem: "terraform"
    directory: "/terraform"
    schedule:
      interval: "weekly"
  
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
```

## Community Engagement

After publishing:
1. Share on LinkedIn/Twitter
2. Submit to awesome-lists:
   - awesome-kubernetes
   - awesome-terraform
   - awesome-cilium
3. Write a blog post
4. Create a demo video
5. Present at meetups

Congratulations! Your repository is now ready to be shared with the community! 🎉
