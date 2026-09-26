terraform {
  required_version = ">= 1.5"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = "00000000-0000-0000-0000-000000000000"
}

# Neutral placeholder IDs — example is validate-only, never applied.
locals {
  subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example/providers/Microsoft.Network/virtualNetworks/example/subnets/private-endpoints"
  dns_zone  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example/providers/Microsoft.Network/privateDnsZones/privatelink.postgres.database.azure.com"
}

module "postgres" {
  source = "../../modules/postgres"

  resource_group_name = "example-rg"
  location            = "eastus"
  name_prefix         = "example"
  loc_short           = "eus"
  sku_name            = "GP_Standard_D2ds_v5"
  storage_mb          = 32768
  tenant_id           = "00000000-0000-0000-0000-000000000000"

  aad_admin_object_id      = "00000000-0000-0000-0000-000000000000"
  aad_admin_principal_name = "example-admin"
  aad_admin_principal_type = "Group"

  # v0.2.0: required database name + opt-in extension allowlist.
  database_name     = "appdb"
  server_extensions = ["VECTOR"]

  # v0.2.0: real private endpoint wiring.
  enable_private_endpoints   = true
  private_endpoint_subnet_id = local.subnet_id
  private_dns_zone_id        = local.dns_zone

  tags = { environment = "example" }
}
