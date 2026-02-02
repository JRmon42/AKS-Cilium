#!/bin/bash

echo "==========================================="
echo "Prerequisites Installation Guide"
echo "==========================================="
echo ""

# Detect OS
OS="$(uname -s)"
case "${OS}" in
    Linux*)     PLATFORM=Linux;;
    Darwin*)    PLATFORM=Mac;;
    *)          PLATFORM="UNKNOWN:${OS}"
esac

echo "Detected platform: $PLATFORM"
echo ""

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Azure CLI
echo "Checking Azure CLI..."
if command_exists az; then
    echo "✓ Azure CLI already installed: $(az --version | head -n1)"
else
    echo "✗ Azure CLI not found"
    echo "Install with:"
    if [ "$PLATFORM" = "Mac" ]; then
        echo "  brew install azure-cli"
    elif [ "$PLATFORM" = "Linux" ]; then
        echo "  curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash"
    fi
fi
echo ""

# Terraform
echo "Checking Terraform..."
if command_exists terraform; then
    echo "✓ Terraform already installed: $(terraform version | head -n1)"
else
    echo "✗ Terraform not found"
    echo "Install from: https://www.terraform.io/downloads"
    if [ "$PLATFORM" = "Mac" ]; then
        echo "  brew install terraform"
    fi
fi
echo ""

# kubectl
echo "Checking kubectl..."
if command_exists kubectl; then
    echo "✓ kubectl already installed: $(kubectl version --client --short 2>/dev/null || kubectl version --client)"
else
    echo "✗ kubectl not found"
    echo "Install with:"
    if [ "$PLATFORM" = "Mac" ]; then
        echo "  brew install kubectl"
    elif [ "$PLATFORM" = "Linux" ]; then
        echo "  curl -LO https://dl.k8s.io/release/\$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
        echo "  chmod +x kubectl && sudo mv kubectl /usr/local/bin/"
    fi
fi
echo ""

# Helm
echo "Checking Helm..."
if command_exists helm; then
    echo "✓ Helm already installed: $(helm version --short)"
else
    echo "✗ Helm not found"
    echo "Install with:"
    if [ "$PLATFORM" = "Mac" ]; then
        echo "  brew install helm"
    elif [ "$PLATFORM" = "Linux" ]; then
        echo "  curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash"
    fi
fi
echo ""

# Cilium CLI
echo "Checking Cilium CLI..."
if command_exists cilium; then
    echo "✓ Cilium CLI already installed: $(cilium version --client 2>/dev/null | grep 'cilium-cli' || echo 'installed')"
else
    echo "✗ Cilium CLI not found"
    echo "Install with:"
    if [ "$PLATFORM" = "Mac" ]; then
        echo "  brew install cilium-cli"
    elif [ "$PLATFORM" = "Linux" ]; then
        echo "  CILIUM_CLI_VERSION=\$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)"
        echo "  CLI_ARCH=amd64"
        echo "  curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/\${CILIUM_CLI_VERSION}/cilium-linux-\${CLI_ARCH}.tar.gz{,.sha256sum}"
        echo "  sha256sum --check cilium-linux-\${CLI_ARCH}.tar.gz.sha256sum"
        echo "  sudo tar xzvfC cilium-linux-\${CLI_ARCH}.tar.gz /usr/local/bin"
        echo "  rm cilium-linux-\${CLI_ARCH}.tar.gz{,.sha256sum}"
    fi
fi
echo ""

# jq
echo "Checking jq..."
if command_exists jq; then
    echo "✓ jq already installed"
else
    echo "✗ jq not found (optional but recommended)"
    echo "Install with:"
    if [ "$PLATFORM" = "Mac" ]; then
        echo "  brew install jq"
    elif [ "$PLATFORM" = "Linux" ]; then
        echo "  sudo apt-get install jq  # Ubuntu/Debian"
        echo "  sudo yum install jq      # CentOS/RHEL"
    fi
fi
echo ""

echo "==========================================="
echo "Summary"
echo "==========================================="
echo ""
ALL_INSTALLED=true

if ! command_exists az; then ALL_INSTALLED=false; fi
if ! command_exists terraform; then ALL_INSTALLED=false; fi
if ! command_exists kubectl; then ALL_INSTALLED=false; fi
if ! command_exists helm; then ALL_INSTALLED=false; fi
if ! command_exists cilium; then ALL_INSTALLED=false; fi

if [ "$ALL_INSTALLED" = true ]; then
    echo "✓ All required tools are installed!"
    echo "You're ready to deploy the AKS cluster."
    echo ""
    echo "Next steps:"
    echo "  1. Login to Azure: az login"
    echo "  2. Run deployment: ./scripts/deploy.sh"
else
    echo "✗ Some tools are missing. Please install them before proceeding."
fi
