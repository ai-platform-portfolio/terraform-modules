terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

locals {
  # Derive a UAMI name from the caller's logical key — no solution-specific
  # names baked into the module.
  workload_names = {
    for k, w in var.workloads :
    k => "${var.name_prefix}-${replace(k, "_", "-")}-${var.loc_short}"
  }

  # Flatten any per-workload extra federated subjects into a single map keyed
  # by "<workload>.<label>" so each becomes its own federated credential.
  extra_federations = merge([
    for k, w in var.workloads : {
      for label, subject in w.extra_federated_subjects :
      "${k}.${label}" => {
        workload = k
        subject  = subject
      }
    }
  ]...)
}

resource "azurerm_user_assigned_identity" "this" {
  for_each            = var.workloads
  name                = local.workload_names[each.key]
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

resource "azurerm_federated_identity_credential" "this" {
  for_each  = var.workloads
  name      = "${local.workload_names[each.key]}-fed"
  parent_id = azurerm_user_assigned_identity.this[each.key].id

  audience = ["api://AzureADTokenExchange"]
  issuer   = var.oidc_issuer_url
  subject  = "system:serviceaccount:${each.value.namespace}:${each.value.sa_name}"
}

# Additional federations for a workload's UAMI (generalised form of the old
# KEDA-operator special case). E.g. an autoscaler operator pod authenticating
# with a worker's identity to read queue depth.
resource "azurerm_federated_identity_credential" "extra" {
  for_each  = local.extra_federations
  name      = "${local.workload_names[each.value.workload]}-${replace(each.key, ".", "-")}-fed"
  parent_id = azurerm_user_assigned_identity.this[each.value.workload].id

  audience = ["api://AzureADTokenExchange"]
  issuer   = var.oidc_issuer_url
  subject  = each.value.subject
}
