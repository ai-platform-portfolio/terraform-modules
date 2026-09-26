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

locals {
  subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example/providers/Microsoft.Network/virtualNetworks/example/subnets/private-endpoints"
  dns_zone  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net"
}

module "storage" {
  source = "../../modules/storage"

  resource_group_name = "example-rg"
  location            = "eastus"
  name_prefix         = "example"
  loc_short           = "eus"

  # v0.2.0: caller-defined containers / role assignments / lifecycle rules.
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

  # v0.2.0: real blob private endpoint wiring.
  enable_private_endpoints   = true
  private_endpoint_subnet_id = local.subnet_id
  private_dns_zone_id        = local.dns_zone

  tags = { environment = "example" }
}
