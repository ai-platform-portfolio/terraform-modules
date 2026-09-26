# Mocked providers — plan-only, never touches live Azure.
mock_provider "azurerm" {}
mock_provider "random" {}

variables {
  resource_group_name = "test-rg"
  location            = "eastus"
  name_prefix         = "test"
  loc_short           = "eus"
  embedding_capacity  = 50
  chat_capacity       = 50
}

run "neutral_defaults_no_facade" {
  command = plan

  variables {
    enable_private_endpoints = false
  }

  assert {
    condition     = length(azurerm_role_assignment.openai_user) == 0
    error_message = "default openai_user_principal_ids = [] must create no role assignments"
  }
  assert {
    condition     = length(azurerm_private_endpoint.account) == 0
    error_message = "no private endpoint expected when disabled"
  }
  assert {
    condition     = azurerm_cognitive_account.this.public_network_access_enabled == true
    error_message = "public access should be enabled when private endpoints off"
  }
}

run "configured_roles_and_real_pe" {
  command = plan

  variables {
    openai_user_principal_ids = [
      "00000000-0000-0000-0000-000000000000",
      "11111111-1111-1111-1111-111111111111",
    ]
    enable_private_endpoints   = true
    private_endpoint_subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example/providers/Microsoft.Network/virtualNetworks/example/subnets/pe"
    private_dns_zone_id        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example/providers/Microsoft.Network/privateDnsZones/privatelink.openai.azure.com"
  }

  assert {
    condition     = length(azurerm_role_assignment.openai_user) == 2
    error_message = "expected one role assignment per principal id"
  }
  assert {
    condition     = length(azurerm_private_endpoint.account) == 1
    error_message = "a real account private endpoint must exist when enabled"
  }
  assert {
    condition     = azurerm_cognitive_account.this.public_network_access_enabled == false
    error_message = "public access should be disabled when private endpoints on"
  }
}
