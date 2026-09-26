output "primary_fqdn" {
  value = azurerm_postgresql_flexible_server.primary.fqdn
}

output "replica_fqdn" {
  value = azurerm_postgresql_flexible_server.replica.fqdn
}

output "admin_login" {
  value = azurerm_postgresql_flexible_server.primary.administrator_login
}

output "database_name" {
  value = azurerm_postgresql_flexible_server_database.this.name
}

output "primary_private_endpoint_id" {
  description = "ID of the primary private endpoint (null when private endpoints disabled)."
  value       = var.enable_private_endpoints ? azurerm_private_endpoint.primary[0].id : null
}

output "replica_private_endpoint_id" {
  description = "ID of the replica private endpoint (null when private endpoints disabled)."
  value       = var.enable_private_endpoints ? azurerm_private_endpoint.replica[0].id : null
}
