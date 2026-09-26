# Mocked providers — plan-only, never touches live Azure.
mock_provider "azurerm" {}
mock_provider "random" {}

variables {
  resource_group_name      = "test-rg"
  location                 = "eastus"
  name_prefix              = "test"
  loc_short                = "eus"
  sku_name                 = "GP_Standard_D2ds_v5"
  storage_mb               = 32768
  tenant_id                = "00000000-0000-0000-0000-000000000000"
  aad_admin_object_id      = "00000000-0000-0000-0000-000000000000"
  aad_admin_principal_name = "test-admin"
  aad_admin_principal_type = "Group"
  database_name            = "appdb"
}

run "neutral_defaults_no_facade" {
  command = plan

  variables {
    enable_private_endpoints = false
  }

  assert {
    condition     = azurerm_postgresql_flexible_server_database.this.name == "appdb"
    error_message = "database_name var must drive the created database name"
  }
  assert {
    condition     = length(azurerm_postgresql_flexible_server_configuration.extensions) == 0
    error_message = "extensions config must not exist with empty server_extensions"
  }
  assert {
    condition     = length(azurerm_private_endpoint.primary) == 0
    error_message = "no private endpoint expected when disabled"
  }
  assert {
    condition     = azurerm_postgresql_flexible_server.primary.public_network_access_enabled == true
    error_message = "public access should be enabled when private endpoints off"
  }
}

run "real_private_endpoints_and_extensions" {
  command = plan

  variables {
    server_extensions          = ["VECTOR"]
    enable_private_endpoints   = true
    private_endpoint_subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example/providers/Microsoft.Network/virtualNetworks/example/subnets/pe"
    private_dns_zone_id        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example/providers/Microsoft.Network/privateDnsZones/privatelink.postgres.database.azure.com"
  }

  assert {
    condition     = length(azurerm_postgresql_flexible_server_configuration.extensions) == 1
    error_message = "extensions config must exist when server_extensions set"
  }
  assert {
    condition     = length(azurerm_private_endpoint.primary) == 1
    error_message = "a real primary private endpoint must exist when enabled"
  }
  assert {
    condition     = length(azurerm_private_endpoint.replica) == 1
    error_message = "a real replica private endpoint must exist when enabled"
  }
  assert {
    condition     = azurerm_postgresql_flexible_server.primary.public_network_access_enabled == false
    error_message = "public access should be disabled when private endpoints on"
  }
}
