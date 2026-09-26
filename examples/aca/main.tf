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

# Neutral placeholder IDs — example is validate-only, never applied.
locals {
  aca_subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example/providers/Microsoft.Network/virtualNetworks/example/subnets/aca-environment"
  uami_id       = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example/providers/Microsoft.ManagedIdentity/userAssignedIdentities/example-uami"
  kv_secret_uri = "https://example-kv.vault.azure.net/secrets/anthropic-api-key"
}

module "aca" {
  source = "../../modules/aca"

  resource_group_name = "example-rg"
  location            = "uksouth"
  name_prefix         = "example"
  loc_short           = "uks"

  # VNet-integrated, no public ingress, scale-to-zero.
  infrastructure_subnet_id = local.aca_subnet_id
  internal_ingress_only    = true
  min_replicas             = 0
  max_replicas             = 1

  image                     = "example.azurecr.io/example-app:latest"
  registry_server           = "example.azurecr.io"
  user_assigned_identity_id = local.uami_id

  secrets = [
    { name = "anthropic-api-key", key_vault_secret_id = local.kv_secret_uri },
  ]
  secret_env_vars = { ANTHROPIC_API_KEY = "anthropic-api-key" }
  env_vars        = { SEC_EDGAR_USER_AGENT = "example agent (contact@example.com)" }

  tags = { environment = "example" }
}

# Job variant: an episodic/batch run-to-completion workload (container runs once
# and exits) with a manual on-demand trigger — the correct primitive when there
# is no long-running server to keep alive.
module "aca_job" {
  source = "../../modules/aca"

  workload_kind = "job"

  resource_group_name = "example-rg"
  location            = "uksouth"
  name_prefix         = "example-batch"
  loc_short           = "uks"

  infrastructure_subnet_id = local.aca_subnet_id
  internal_ingress_only    = true

  # Manual trigger sizing.
  job_replica_timeout_in_seconds = 1800
  job_replica_retry_limit        = 1
  job_parallelism                = 1
  job_replica_completion_count   = 1

  image                     = "example.azurecr.io/example-app:latest"
  registry_server           = "example.azurecr.io"
  user_assigned_identity_id = local.uami_id

  secrets = [
    { name = "anthropic-api-key", key_vault_secret_id = local.kv_secret_uri },
  ]
  secret_env_vars = { ANTHROPIC_API_KEY = "anthropic-api-key" }
  env_vars        = { SEC_EDGAR_USER_AGENT = "example agent (contact@example.com)" }

  tags = { environment = "example" }
}
