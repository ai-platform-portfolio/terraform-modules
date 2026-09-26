# Mocked provider — plan-only, never touches live Azure.
mock_provider "azurerm" {}

variables {
  resource_group_name       = "test-rg"
  location                  = "uksouth"
  name_prefix               = "test"
  loc_short                 = "uks"
  image                     = "example.azurecr.io/app:latest"
  user_assigned_identity_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/test-uami"
}

run "defaults_scale_to_zero_no_ingress" {
  command = plan

  assert {
    condition     = azurerm_container_app.this[0].template[0].min_replicas == 0
    error_message = "default min_replicas must be 0 (scale-to-zero)"
  }
  assert {
    condition     = length(azurerm_container_app.this[0].ingress) == 0
    error_message = "no ingress block expected by default"
  }
  assert {
    condition     = length(azurerm_container_app.this[0].registry) == 0
    error_message = "no registry block expected without registry_server"
  }
  assert {
    condition     = length(azurerm_container_app.this[0].secret) == 0
    error_message = "no secret block expected without secrets"
  }
  assert {
    condition     = azurerm_container_app_environment.this.infrastructure_subnet_id == null
    error_message = "environment must not be VNet-integrated by default"
  }
  assert {
    condition     = azurerm_container_app.this[0].name == "test-app-uks"
    error_message = "app name must derive from name_prefix/loc_short"
  }
  assert {
    condition     = length(azurerm_container_app_job.this) == 0
    error_message = "no job resource expected in the default (app) kind"
  }
}

run "internal_private_with_registry_and_kv_secrets" {
  command = plan

  variables {
    infrastructure_subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/net/providers/Microsoft.Network/virtualNetworks/vnet/subnets/aca"
    internal_ingress_only    = true
    registry_server          = "example.azurecr.io"
    secrets = [
      { name = "anthropic-api-key", key_vault_secret_id = "https://example-kv.vault.azure.net/secrets/anthropic-api-key" },
      { name = "audit-database-url", key_vault_secret_id = "https://example-kv.vault.azure.net/secrets/audit-database-url" },
    ]
    secret_env_vars = {
      ANTHROPIC_API_KEY  = "anthropic-api-key"
      AUDIT_DATABASE_URL = "audit-database-url"
    }
    env_vars = { SEC_EDGAR_USER_AGENT = "example agent (contact@example.com)" }
  }

  assert {
    condition     = azurerm_container_app_environment.this.internal_load_balancer_enabled == true
    error_message = "internal_ingress_only must set an internal load balancer"
  }
  assert {
    condition     = length(azurerm_container_app.this[0].registry) == 1
    error_message = "a registry block must exist when registry_server is set"
  }
  assert {
    condition     = length(azurerm_container_app.this[0].secret) == 2
    error_message = "one secret block per secrets entry"
  }
  assert {
    condition     = length(azurerm_container_app.this[0].template[0].container[0].env) == 3
    error_message = "env must include both plain and secret-backed variables"
  }
  assert {
    condition     = azurerm_container_app.this[0].template[0].min_replicas == 0
    error_message = "scale-to-zero preserved in the private posture"
  }
}

run "job_variant_manual_trigger_with_registry_and_secrets" {
  command = plan

  variables {
    workload_kind            = "job"
    infrastructure_subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/net/providers/Microsoft.Network/virtualNetworks/vnet/subnets/aca"
    internal_ingress_only    = true
    registry_server          = "example.azurecr.io"
    secrets = [
      { name = "anthropic-api-key", key_vault_secret_id = "https://example-kv.vault.azure.net/secrets/anthropic-api-key" },
    ]
    secret_env_vars = { ANTHROPIC_API_KEY = "anthropic-api-key" }
    env_vars        = { SEC_EDGAR_USER_AGENT = "example agent (contact@example.com)" }
  }

  assert {
    condition     = length(azurerm_container_app_job.this) == 1
    error_message = "a job resource must exist when workload_kind = job"
  }
  assert {
    condition     = length(azurerm_container_app.this) == 0
    error_message = "no app resource expected in the job kind"
  }
  assert {
    condition     = azurerm_container_app_job.this[0].name == "test-job-uks"
    error_message = "job name must derive from name_prefix/loc_short"
  }
  assert {
    condition     = length(azurerm_container_app_job.this[0].manual_trigger_config) == 1
    error_message = "job must be manually triggered (on-demand)"
  }
  assert {
    condition     = length(azurerm_container_app_job.this[0].registry) == 1
    error_message = "job must authenticate to ACR via the managed identity"
  }
  assert {
    condition     = length(azurerm_container_app_job.this[0].secret) == 1
    error_message = "job must carry the KV-backed secret"
  }
  assert {
    condition     = length(azurerm_container_app_job.this[0].template[0].container[0].env) == 2
    error_message = "job env must include both plain and secret-backed variables"
  }
}

run "http_probes_opt_in_per_path" {
  command = plan

  variables {
    liveness_probe_path  = "/healthz"
    readiness_probe_path = "/readyz"
    ingress_target_port  = 8080
  }

  assert {
    condition     = azurerm_container_app.this[0].template[0].container[0].liveness_probe[0].path == "/healthz"
    error_message = "liveness probe must use liveness_probe_path"
  }
  assert {
    condition     = azurerm_container_app.this[0].template[0].container[0].liveness_probe[0].port == 8080
    error_message = "liveness probe must target ingress_target_port"
  }
  assert {
    condition     = azurerm_container_app.this[0].template[0].container[0].readiness_probe[0].path == "/readyz"
    error_message = "readiness probe must use readiness_probe_path"
  }
  assert {
    condition     = azurerm_container_app.this[0].template[0].container[0].readiness_probe[0].transport == "HTTP"
    error_message = "readiness probe must be HTTP"
  }
}

run "no_probes_by_default" {
  command = plan

  assert {
    condition     = length(azurerm_container_app.this[0].template[0].container[0].liveness_probe) == 0
    error_message = "no liveness probe expected when liveness_probe_path is empty"
  }
  assert {
    condition     = length(azurerm_container_app.this[0].template[0].container[0].readiness_probe) == 0
    error_message = "no readiness probe expected when readiness_probe_path is empty"
  }
}
