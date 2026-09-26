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
  dns_zone  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example/providers/Microsoft.Network/privateDnsZones/privatelink.openai.azure.com"
}

module "openai" {
  source = "../../modules/openai"

  resource_group_name = "example-rg"
  location            = "eastus"
  name_prefix         = "example"
  loc_short           = "eus"

  embedding_capacity = 50
  chat_capacity      = 50

  # v0.2.0: caller-defined set of principals to grant the OpenAI User role.
  openai_user_principal_ids = [
    "00000000-0000-0000-0000-000000000000",
    "11111111-1111-1111-1111-111111111111",
  ]

  # v0.2.0: real account private endpoint wiring.
  enable_private_endpoints   = true
  private_endpoint_subnet_id = local.subnet_id
  private_dns_zone_id        = local.dns_zone

  tags = { environment = "example" }
}
