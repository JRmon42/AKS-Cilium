# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${var.cluster_name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
  tags                = var.tags
}

# Subnet for AKS
resource "azurerm_subnet" "aks" {
  name                 = "snet-aks"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "law" {
  name                = "law-${var.cluster_name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}

# User Assigned Identity for AKS
resource "azurerm_user_assigned_identity" "aks" {
  name                = "id-${var.cluster_name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags
}

# Role Assignment for AKS Identity on Subnet
resource "azurerm_role_assignment" "aks_subnet" {
  scope                = azurerm_subnet.aks.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.aks.principal_id
}

# AKS Cluster with Cilium
resource "azurerm_kubernetes_cluster" "aks" {
  name                      = var.cluster_name
  location                  = azurerm_resource_group.rg.location
  resource_group_name       = azurerm_resource_group.rg.name
  dns_prefix                = var.cluster_name
  kubernetes_version        = var.kubernetes_version
  automatic_channel_upgrade = "stable"
  
  default_node_pool {
    name                = "system"
    node_count          = var.node_count
    vm_size             = var.node_vm_size
    vnet_subnet_id      = azurerm_subnet.aks.id
    enable_auto_scaling = var.enable_auto_scaling
    min_count           = var.enable_auto_scaling ? var.min_count : null
    max_count           = var.enable_auto_scaling ? var.max_count : null
    os_disk_size_gb     = 128
    os_disk_type        = "Managed"
    type                = "VirtualMachineScaleSets"
    
    upgrade_settings {
      max_surge = "33%"
    }
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aks.id]
  }

  network_profile {
    network_plugin      = var.network_plugin
    network_policy      = var.network_policy
    network_data_plane  = var.network_dataplane
    service_cidr        = "10.1.0.0/16"
    dns_service_ip      = "10.1.0.10"
    load_balancer_sku   = "standard"
  }

  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
  }

  monitor_metrics {
    annotations_allowed = null
    labels_allowed      = null
  }

  azure_policy_enabled = true

  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  key_vault_secrets_provider {
    secret_rotation_enabled  = true
    secret_rotation_interval = "2m"
  }

  tags = var.tags

  depends_on = [
    azurerm_role_assignment.aks_subnet
  ]
}

# Prometheus and Grafana using Helm
resource "helm_release" "prometheus" {
  name             = "prometheus"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  namespace        = "monitoring"
  create_namespace = true
  version          = "55.0.0"

  values = [
    file("${path.module}/helm-values/prometheus-values.yaml")
  ]

  depends_on = [azurerm_kubernetes_cluster.aks]
}

# OPA Gatekeeper
resource "helm_release" "gatekeeper" {
  name             = "gatekeeper"
  repository       = "https://open-policy-agent.github.io/gatekeeper/charts"
  chart            = "gatekeeper"
  namespace        = "gatekeeper-system"
  create_namespace = true
  version          = "3.15.0"

  set {
    name  = "auditInterval"
    value = "60"
  }

  set {
    name  = "replicas"
    value = "3"
  }

  depends_on = [azurerm_kubernetes_cluster.aks]
}

# Cilium CLI (for Hubble)
resource "null_resource" "enable_hubble" {
  provisioner "local-exec" {
    command = <<-EOT
      az aks get-credentials --resource-group ${azurerm_resource_group.rg.name} --name ${azurerm_kubernetes_cluster.aks.name} --overwrite-existing
      cilium hubble enable --ui
    EOT
  }

  depends_on = [azurerm_kubernetes_cluster.aks]
}
