terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

resource "random_string" "subdomain_suffix" {
  length  = 5
  upper   = false
  special = false
}

resource "azurerm_cognitive_account" "this" {
  name                = "${var.name_prefix}-aoai-${var.loc_short}"
  resource_group_name = var.resource_group_name
  location            = var.location

  kind     = "OpenAI"
  sku_name = "S0"

  custom_subdomain_name         = "${var.name_prefix}-aoai-${var.loc_short}-${random_string.subdomain_suffix.result}"
  local_auth_enabled            = false
  public_network_access_enabled = !var.enable_private_endpoints

  tags = var.tags
}

resource "azurerm_cognitive_deployment" "embedding" {
  name                 = "embedding"
  cognitive_account_id = azurerm_cognitive_account.this.id

  model {
    format  = "OpenAI"
    name    = "text-embedding-3-small"
    version = "1"
  }

  sku {
    name     = "GlobalStandard"
    capacity = var.embedding_capacity
  }
}

resource "azurerm_cognitive_deployment" "chat" {
  name                 = "chat"
  cognitive_account_id = azurerm_cognitive_account.this.id

  model {
    format  = "OpenAI"
    name    = "gpt-4o-mini"
    version = "2024-07-18"
  }

  sku {
    name     = "GlobalStandard"
    capacity = var.chat_capacity
  }
}

resource "azurerm_role_assignment" "openai_user" {
  for_each             = var.openai_user_principal_ids
  scope                = azurerm_cognitive_account.this.id
  role_definition_name = "Cognitive Services OpenAI User"
  principal_id         = each.value
}

# --- Real private networking (v0.2.0) -------------------------------------
# Previously enable_private_endpoints ONLY flipped public_network_access_enabled
# (a facade). It now provisions a real private endpoint + DNS wiring.
resource "azurerm_private_endpoint" "account" {
  count = var.enable_private_endpoints ? 1 : 0

  name                = "${azurerm_cognitive_account.this.name}-pe"
  resource_group_name = var.resource_group_name
  location            = var.location
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${azurerm_cognitive_account.this.name}-psc"
    private_connection_resource_id = azurerm_cognitive_account.this.id
    subresource_names              = ["account"]
    is_manual_connection           = false
  }

  dynamic "private_dns_zone_group" {
    for_each = var.private_dns_zone_id == "" ? [] : [var.private_dns_zone_id]
    content {
      name                 = "default"
      private_dns_zone_ids = [private_dns_zone_group.value]
    }
  }

  tags = var.tags

  lifecycle {
    precondition {
      condition     = var.private_endpoint_subnet_id != ""
      error_message = "enable_private_endpoints = true requires private_endpoint_subnet_id to be set."
    }
  }
}
