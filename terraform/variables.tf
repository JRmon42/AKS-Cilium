variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "rg-aks-cilium-demo"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "swedencentral"
}

variable "cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
  default     = "aks-cilium-demo"
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.33"
}

variable "node_count" {
  description = "Number of nodes in the default node pool"
  type        = number
  default     = 3
}

variable "node_vm_size" {
  description = "VM size for the nodes"
  type        = string
  default     = "Standard_D4s_v3"
}

variable "enable_auto_scaling" {
  description = "Enable auto-scaling for the node pool"
  type        = bool
  default     = true
}

variable "min_count" {
  description = "Minimum number of nodes"
  type        = number
  default     = 2
}

variable "max_count" {
  description = "Maximum number of nodes"
  type        = number
  default     = 5
}

variable "network_plugin" {
  description = "Network plugin to use (azure = Azure CNI with CNS)"
  type        = string
  default     = "azure"
}

variable "network_dataplane" {
  description = "Network dataplane (cilium = eBPF-based dataplane for advanced networking)"
  type        = string
  default     = "cilium"
}

variable "network_plugin_mode" {
  description = "Network plugin mode (overlay = Azure CNS overlay networking, no subnet IP exhaustion)"
  type        = string
  default     = "overlay"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    Environment = "Demo"
    Project     = "AKS-Cilium"
    ManagedBy   = "Terraform"
  }
}
