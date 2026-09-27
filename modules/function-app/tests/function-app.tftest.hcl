mock_provider "azurerm" {}

variables {
  name                = "fixture-function"
  resource_group_name = "fixture-rg"
  location            = "uksouth"
  subnet_id           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/fixture-rg/providers/Microsoft.Network/virtualNetworks/fixture/subnets/functions"
  storage = {
    id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/fixture-rg/providers/Microsoft.Storage/storageAccounts/fixturestorage"
    name          = "fixturestorage"
    blob_endpoint = "https://fixturestorage.blob.core.windows.net/"
  }
  queues           = ["profile-sync", "profile-sync-poison"]
  role_assignments = {}
}

run "runtime_access_excludes_state_and_uses_the_approved_network" {
  command = plan
  assert {
    condition = alltrue([
      for role in azurerm_role_assignment.this :
      role.scope != var.storage.id && !endswith(role.scope, "/containers/tfstate")
    ])
    error_message = "Runtime storage permissions must not include account-wide or Terraform state access."
  }
  assert {
    condition = (
      azurerm_function_app_flex_consumption.this.virtual_network_subnet_id == var.subnet_id &&
      azurerm_function_app_flex_consumption.this.https_only &&
      azurerm_function_app_flex_consumption.this.public_network_access_enabled &&
      !azurerm_function_app_flex_consumption.this.webdeploy_publish_basic_authentication_enabled
    )
    error_message = "Use the caller's subnet, public HTTPS webhook ingress and authenticated deployment."
  }
  assert {
    condition     = azurerm_function_app_flex_consumption.this.storage_authentication_type == "UserAssignedIdentity"
    error_message = "Storage keys must not be used for Function authentication."
  }
}
