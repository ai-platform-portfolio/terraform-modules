# Mocked providers — plan-only, never touches live Azure.
mock_provider "azurerm" {}
mock_provider "random" {}

variables {
  resource_group_name = "test-rg"
  location            = "eastus"
  name_prefix         = "test"
  loc_short           = "eus"
}

run "neutral_defaults_no_facade" {
  command = plan

  variables {
    enable_private_endpoints = false
  }

  assert {
    condition     = length(azurerm_storage_container.this) == 0
    error_message = "default containers = [] must create none"
  }
  assert {
    condition     = length(azurerm_storage_management_policy.this) == 0
    error_message = "no lifecycle policy expected with empty lifecycle_rules"
  }
  assert {
    condition     = length(azurerm_role_assignment.this) == 0
    error_message = "no role assignments expected by default"
  }
  assert {
    condition     = length(azurerm_private_endpoint.blob) == 0
    error_message = "no private endpoint expected when disabled"
  }
}

run "configured_containers_roles_lifecycle_and_pe" {
  command = plan

  variables {
    containers = ["assets", "exports"]
    role_assignments = {
      writer = {
        principal_id         = "00000000-0000-0000-0000-000000000000"
        role_definition_name = "Storage Blob Data Contributor"
      }
      reader = {
        principal_id         = "11111111-1111-1111-1111-111111111111"
        role_definition_name = "Storage Blob Data Reader"
      }
    }
    lifecycle_rules = [
      {
        name                    = "cool-old-exports"
        prefix_match            = ["exports/archive/"]
        tier_to_cool_after_days = 30
      }
    ]
    enable_private_endpoints   = true
    private_endpoint_subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example/providers/Microsoft.Network/virtualNetworks/example/subnets/pe"
    private_dns_zone_id        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net"
  }

  assert {
    condition     = length(azurerm_storage_container.this) == 2
    error_message = "expected two containers"
  }
  assert {
    condition     = length(azurerm_role_assignment.this) == 2
    error_message = "expected two role assignments"
  }
  assert {
    condition     = length(azurerm_storage_management_policy.this) == 1
    error_message = "expected one lifecycle management policy"
  }
  assert {
    condition     = length(azurerm_private_endpoint.blob) == 1
    error_message = "a real blob private endpoint must exist when enabled"
  }
  assert {
    condition     = azurerm_storage_account.this.public_network_access_enabled == false
    error_message = "public access should be disabled when private endpoints on"
  }
}
