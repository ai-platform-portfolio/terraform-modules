terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

resource "azurerm_storage_account" "this" {
  name                = "${var.name_prefix}st${var.loc_short}${random_string.suffix.result}"
  resource_group_name = var.resource_group_name
  location            = var.location

  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  access_tier              = "Hot"

  shared_access_key_enabled       = false
  public_network_access_enabled   = !var.enable_private_endpoints
  https_traffic_only_enabled      = true
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  default_to_oauth_authentication = true

  blob_properties {
    last_access_time_enabled = true
    versioning_enabled       = false
    change_feed_enabled      = false
  }

  tags = var.tags
}

resource "azurerm_storage_container" "this" {
  for_each              = var.containers
  name                  = each.value
  storage_account_id    = azurerm_storage_account.this.id
  container_access_type = "private"
}

# Lifecycle management policy — only created when the caller supplies rules.
resource "azurerm_storage_management_policy" "this" {
  count              = length(var.lifecycle_rules) > 0 ? 1 : 0
  storage_account_id = azurerm_storage_account.this.id

  dynamic "rule" {
    for_each = { for r in var.lifecycle_rules : r.name => r }
    content {
      name    = rule.value.name
      enabled = true

      filters {
        blob_types   = ["blockBlob"]
        prefix_match = rule.value.prefix_match
      }

      actions {
        base_blob {
          tier_to_cool_after_days_since_modification_greater_than    = rule.value.tier_to_cool_after_days
          tier_to_archive_after_days_since_modification_greater_than = rule.value.tier_to_archive_after_days
          delete_after_days_since_modification_greater_than          = rule.value.delete_after_days
        }
      }
    }
  }
}

resource "azurerm_role_assignment" "this" {
  for_each             = var.role_assignments
  scope                = azurerm_storage_account.this.id
  role_definition_name = each.value.role_definition_name
  principal_id         = each.value.principal_id
}

# --- Real private networking (v0.2.0) -------------------------------------
# Previously enable_private_endpoints ONLY flipped public_network_access_enabled
# (a facade). It now provisions a real blob private endpoint + DNS wiring.
resource "azurerm_private_endpoint" "blob" {
  count = var.enable_private_endpoints ? 1 : 0

  name                = "${azurerm_storage_account.this.name}-blob-pe"
  resource_group_name = var.resource_group_name
  location            = var.location
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${azurerm_storage_account.this.name}-blob-psc"
    private_connection_resource_id = azurerm_storage_account.this.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  dynamic "private_dns_zone_group" {
    for_each = var.private_dns_zone_id == "" ? [] : [var.private_dns_zone_id]
    content {
      name                 = "default"
      private_dns_zone_ids = [private_dns_zone_group.value]
    }
  }

  tags = var.tags

  lifecycle {
    precondition {
      condition     = var.private_endpoint_subnet_id != ""
      error_message = "enable_private_endpoints = true requires private_endpoint_subnet_id to be set."
    }
  }
}
