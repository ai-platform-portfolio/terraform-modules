terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "embed_spot" {
  name                  = "embedspot"
  kubernetes_cluster_id = var.aks_cluster_id

  vm_size = "Standard_D4ds_v5"
  mode    = "User"
  os_type = "Linux"

  auto_scaling_enabled = true
  min_count            = 0
  max_count            = 10
  node_count           = 0

  priority        = "Spot"
  eviction_policy = "Delete"
  spot_max_price  = var.spot_max_price

  node_labels = {
    "kubernetes.azure.com/scalesetpriority" = "spot"
    "workload"                              = "embed"
  }

  node_taints = [
    "kubernetes.azure.com/scalesetpriority=spot:NoSchedule",
    "workload=embed:NoSchedule",
  ]

  tags = var.tags

  lifecycle {
    # AKS itself may drift node_count / vm_size / kubelet_config under
    # auto-scaling; the rotation would destructively recreate the pool.
    ignore_changes = [
      node_count,
      vm_size,
      kubelet_config,
      kubelet_disk_type,
      linux_os_config,
      max_pods,
      os_disk_size_gb,
      os_disk_type,
      zones,
      fips_enabled,
      host_encryption_enabled,
      node_public_ip_enabled,
      pod_subnet_id,
      snapshot_id,
      ultra_ssd_enabled,
      vnet_subnet_id,
    ]
  }
}
