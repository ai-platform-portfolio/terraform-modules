resource "auth0_resource_server" "apis" {
  for_each = var.auth0_apis

  name        = each.value.name
  identifier  = each.key
  signing_alg = "RS256"

  token_lifetime       = each.value.token_lifetime
  allow_offline_access = each.value.allow_offline

  skip_consent_for_verifiable_first_party_clients = false
}

resource "auth0_resource_server_scopes" "api_scopes" {
  for_each = var.auth0_apis

  resource_server_identifier = each.key

  dynamic "scopes" {
    for_each = each.value.scopes
    content {
      name        = scopes.key
      description = scopes.value
    }
  }

  depends_on = [auth0_resource_server.apis]
}

resource "auth0_client" "clients" {
  for_each = var.auth0_clients

  name     = each.value.name
  app_type = each.value.app_type

  callbacks           = each.value.callbacks
  allowed_logout_urls = each.value.logout_urls
  grant_types         = each.value.grant_types

  oidc_conformant = true

  jwt_configuration {
    alg = "RS256"
  }
}

resource "auth0_client_credentials" "clients" {
  for_each = var.auth0_clients

  client_id             = auth0_client.clients[each.key].id
  authentication_method = each.value.authentication_method
}

resource "auth0_client_grant" "m2m" {
  for_each = { for k, v in var.auth0_clients : k => v if v.api_identifier != null }

  client_id = auth0_client.clients[each.key].id
  audience  = each.value.api_identifier
  scopes    = each.value.api_scopes
}

resource "azurerm_key_vault_secret" "api_identifier" {
  for_each = var.auth0_apis

  name         = "auth0-api-${replace(lower(each.value.name), " ", "-")}"
  value        = each.key
  key_vault_id = var.key_vault_id
}

resource "azurerm_key_vault_secret" "client_id" {
  for_each = var.auth0_clients

  name         = "auth0-client-id-${each.key}"
  value        = auth0_client.clients[each.key].client_id
  key_vault_id = var.key_vault_id
}

resource "azurerm_key_vault_secret" "client_secret" {
  for_each = { for k, v in var.auth0_clients : k => v if v.authentication_method == "client_secret_post" }

  name         = "auth0-client-secret-${each.key}"
  value        = auth0_client_credentials.clients[each.key].client_secret
  key_vault_id = var.key_vault_id
}
