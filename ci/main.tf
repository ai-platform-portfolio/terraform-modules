module "network" {
  source = "../modules/network"

  resource_group_name = var.network.resource_group_name
  location            = var.network.location
  name                = var.network.name
  address_space       = var.network.address_space
  subnets             = var.network.subnets
  private_dns_zones   = var.network.private_dns_zones
  tags                = var.network.tags
}
