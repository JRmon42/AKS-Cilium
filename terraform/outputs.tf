output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.rg.name
}

output "cluster_name" {
  description = "Name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.name
}

output "cluster_id" {
  description = "ID of the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.id
}

output "kube_config" {
  description = "Kubernetes configuration"
  value       = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive   = true
}

output "cluster_fqdn" {
  description = "FQDN of the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.fqdn
}

output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.law.id
}

output "get_credentials_command" {
  description = "Command to get AKS credentials"
  value       = "az aks get-credentials --resource-group ${azurerm_resource_group.rg.name} --name ${azurerm_kubernetes_cluster.aks.name}"
}

output "hubble_ui_command" {
  description = "Command to access Hubble UI"
  value       = "cilium hubble ui"
}

output "grafana_command" {
  description = "Command to access Grafana"
  value       = "kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80"
}

output "portal_cluster_url" {
  description = "Azure Portal URL for AKS cluster"
  value       = "https://portal.azure.com/#@/resource${azurerm_kubernetes_cluster.aks.id}"
}

output "portal_resource_group_url" {
  description = "Azure Portal URL for resource group"
  value       = "https://portal.azure.com/#@/resource${azurerm_resource_group.rg.id}"
}

output "portal_monitoring_url" {
  description = "Azure Portal URL for Container Insights"
  value       = "https://portal.azure.com/#@/resource${azurerm_kubernetes_cluster.aks.id}/containerInsights"
}

output "network_configuration" {
  description = "Network configuration summary"
  value = {
    network_plugin      = "azure"
    network_plugin_mode = "overlay (Azure CNS)"
    network_dataplane   = "cilium (eBPF)"
    service_cidr        = "10.1.0.0/16"
    pod_cidr            = "Managed by Azure CNS"
  }
}
