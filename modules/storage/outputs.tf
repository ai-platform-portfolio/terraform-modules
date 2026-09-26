output "account_name" {
  value = azurerm_storage_account.this.name
}

output "account_id" {
  value = azurerm_storage_account.this.id
}

output "primary_blob_endpoint" {
  value = azurerm_storage_account.this.primary_blob_endpoint
}

# v0.2.0: map of created container names keyed by the caller's container name,
# replacing the previous single fixed "container_name" output.
output "container_names" {
  description = "Names of the created blob containers."
  value       = { for k, c in azurerm_storage_container.this : k => c.name }
}

output "blob_private_endpoint_id" {
  description = "ID of the blob private endpoint (null when private endpoints disabled)."
  value       = var.enable_private_endpoints ? azurerm_private_endpoint.blob[0].id : null
}
