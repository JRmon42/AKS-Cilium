#!/bin/bash
set -e

echo "==========================================="
echo "AKS Cleanup Script"
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

# Warning
print_red "WARNING: This will destroy all resources created by Terraform!"
echo ""
read -p "Are you sure you want to continue? (type 'yes' to confirm): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    print_yellow "Cleanup cancelled"
    exit 0
fi
echo ""

# Change to terraform directory
cd terraform

# Destroy
print_yellow "Destroying infrastructure..."
terraform destroy -auto-approve

print_green "All resources have been destroyed"
echo ""
echo "Cleanup completed successfully!"
