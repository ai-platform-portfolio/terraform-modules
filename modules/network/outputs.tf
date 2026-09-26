output "vnet_id" { value = azurerm_virtual_network.this.id }
output "subnet_ids" { value = { for key, subnet in azurerm_subnet.this : key => subnet.id } }
output "private_dns_zone_ids" { value = { for key, zone in azurerm_private_dns_zone.this : key => zone.id } }
