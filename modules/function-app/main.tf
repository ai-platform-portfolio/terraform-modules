terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

resource "azurerm_user_assigned_identity" "this" {
  name                = "${var.name}-runtime"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

resource "azurerm_service_plan" "this" {
  name                = "${var.name}-plan"
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = "Linux"
  sku_name            = "FC1"
  tags                = var.tags
}

resource "azurerm_storage_container" "this" {
  for_each              = toset(concat(["${var.name}-deployment"], var.create_host_containers ? ["azure-webjobs-hosts", "azure-webjobs-secrets"] : []))
  name                  = each.key
  storage_account_id    = var.storage.id
  container_access_type = "private"
}

resource "azurerm_storage_queue" "this" {
  for_each           = var.queues
  name               = each.key
  storage_account_id = var.storage.id
}

locals {
  access = merge(var.role_assignments, {
    for name in ["azure-webjobs-hosts", "azure-webjobs-secrets", "${var.name}-deployment"] : "blob-${name}" => {
      scope = "${var.storage.id}/blobServices/default/containers/${name}"
      role  = "Storage Blob Data Owner"
    }
    }, {
    for name, queue in azurerm_storage_queue.this : "queue-${name}" => {
      scope = "${var.storage.id}/queueServices/default/queues/${name}"
      role  = "Storage Queue Data Contributor"
    }
  })
}

resource "azurerm_role_assignment" "this" {
  for_each             = nonsensitive(toset(keys(local.access)))
  scope                = local.access[each.key].scope
  role_definition_name = local.access[each.key].role
  principal_id         = azurerm_user_assigned_identity.this.principal_id
  principal_type       = "ServicePrincipal"
  depends_on           = [azurerm_storage_container.this, azurerm_storage_queue.this]
}

resource "azurerm_function_app_flex_consumption" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  service_plan_id     = azurerm_service_plan.this.id

  runtime_name                      = "python"
  runtime_version                   = "3.12"
  instance_memory_in_mb             = 2048
  maximum_instance_count            = 40
  storage_container_type            = "blobContainer"
  storage_container_endpoint        = "${var.storage.blob_endpoint}${azurerm_storage_container.this["${var.name}-deployment"].name}"
  storage_authentication_type       = "UserAssignedIdentity"
  storage_user_assigned_identity_id = azurerm_user_assigned_identity.this.id

  virtual_network_subnet_id                      = var.subnet_id
  public_network_access_enabled                  = true
  https_only                                     = true
  webdeploy_publish_basic_authentication_enabled = false

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.this.id]
  }

  app_settings = merge(var.app_settings, {
    AZURE_CLIENT_ID                  = azurerm_user_assigned_identity.this.client_id
    AzureWebJobsStorage__accountName = var.storage.name
    AzureWebJobsStorage__credential  = "managedidentity"
    AzureWebJobsStorage__clientId    = azurerm_user_assigned_identity.this.client_id
  })

  site_config {
    minimum_tls_version = "1.2"
  }
  tags       = var.tags
  depends_on = [azurerm_role_assignment.this]
}
