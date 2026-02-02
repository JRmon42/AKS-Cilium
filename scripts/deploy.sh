#!/bin/bash
set -e

echo "==========================================="
echo "AKS Deployment Script"
echo "==========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_green() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_red() {
    echo -e "${RED}✗ $1${NC}"
}

print_yellow() {
    echo -e "${YELLOW}➜ $1${NC}"
}

# Check prerequisites
print_yellow "Checking prerequisites..."
command -v az >/dev/null 2>&1 || { print_red "Azure CLI is required but not installed. Aborting."; exit 1; }
command -v terraform >/dev/null 2>&1 || { print_red "Terraform is required but not installed. Aborting."; exit 1; }
command -v kubectl >/dev/null 2>&1 || { print_red "kubectl is required but not installed. Aborting."; exit 1; }
command -v cilium >/dev/null 2>&1 || { print_red "Cilium CLI is required but not installed. Aborting."; exit 1; }
print_green "All prerequisites found"
echo ""

# Check Azure login
print_yellow "Checking Azure login status..."
if az account show > /dev/null 2>&1; then
    SUBSCRIPTION_NAME=$(az account show --query name -o tsv)
    SUBSCRIPTION_ID=$(az account show --query id -o tsv)
    print_green "Logged in to Azure"
    echo "  Subscription: $SUBSCRIPTION_NAME"
    echo "  ID: $SUBSCRIPTION_ID"
else
    print_red "Not logged in to Azure. Please run 'az login'"
    exit 1
fi
echo ""

# Confirm deployment
print_yellow "This will deploy:"
echo "  - AKS cluster with Cilium CNI"
echo "  - Prometheus & Grafana monitoring"
echo "  - OPA Gatekeeper"
echo "  - Log Analytics workspace"
echo ""
read -p "Continue? (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    print_yellow "Deployment cancelled"
    exit 0
fi
echo ""

# Change to terraform directory
cd terraform

# Initialize Terraform
print_yellow "Initializing Terraform..."
terraform init
print_green "Terraform initialized"
echo ""

# Create terraform.tfvars if it doesn't exist
if [ ! -f terraform.tfvars ]; then
    print_yellow "Creating terraform.tfvars from example..."
    cp terraform.tfvars.example terraform.tfvars
    print_green "Created terraform.tfvars - please review and update if needed"
fi

# Plan
print_yellow "Running Terraform plan..."
terraform plan -out=tfplan
print_green "Plan created"
echo ""

# Apply
print_yellow "Applying Terraform configuration..."
terraform apply tfplan
print_green "Infrastructure deployed"
echo ""

# Get credentials
print_yellow "Getting AKS credentials..."
RESOURCE_GROUP=$(terraform output -raw resource_group_name)
CLUSTER_NAME=$(terraform output -raw cluster_name)
az aks get-credentials --resource-group "$RESOURCE_GROUP" --name "$CLUSTER_NAME" --overwrite-existing
print_green "Credentials configured"
echo ""

# Verify Cilium
print_yellow "Verifying Cilium installation..."
kubectl wait --for=condition=ready pod -l k8s-app=cilium -n kube-system --timeout=300s
cilium status --wait
print_green "Cilium is ready"
echo ""

# Enable Hubble UI
print_yellow "Enabling Hubble UI..."
cilium hubble enable --ui
print_green "Hubble UI enabled"
echo ""

# Display outputs
print_green "Deployment completed successfully!"
echo ""
echo "==========================================="
echo "Deployment Information"
echo "==========================================="
terraform output
echo ""
echo "Next steps:"
echo "  1. Run network policies demo: ./demos/01-network-policies/run-demo.sh"
echo "  2. Run monitoring demo: ./demos/02-monitoring/run-demo.sh"
echo "  3. Run constraints demo: ./demos/03-constraints/run-demo.sh"
echo ""
echo "Access dashboards:"
echo "  Grafana: kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80"
echo "  Prometheus: kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090"
echo "  Hubble UI: cilium hubble ui"
