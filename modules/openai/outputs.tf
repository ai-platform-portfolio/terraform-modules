output "endpoint" {
  value = azurerm_cognitive_account.this.endpoint
}

output "account_name" {
  value = azurerm_cognitive_account.this.name
}

output "embedding_deployment" {
  value = azurerm_cognitive_deployment.embedding.name
}

output "chat_deployment" {
  value = azurerm_cognitive_deployment.chat.name
}

output "private_endpoint_id" {
  description = "ID of the account private endpoint (null when private endpoints disabled)."
  value       = var.enable_private_endpoints ? azurerm_private_endpoint.account[0].id : null
}
