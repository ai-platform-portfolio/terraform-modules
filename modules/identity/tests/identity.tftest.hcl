# Mocked provider — plan-only, never touches live Azure.
mock_provider "azurerm" {}

variables {
  resource_group_name = "test-rg"
  location            = "eastus"
  name_prefix         = "test"
  loc_short           = "eus"
  oidc_issuer_url     = "https://issuer.example/"
}

run "empty_default_creates_nothing" {
  command = plan

  assert {
    condition     = length(azurerm_user_assigned_identity.this) == 0
    error_message = "default workloads = {} must create no identities"
  }
}

run "map_based_workloads_and_extra_federation" {
  command = plan

  variables {
    workloads = {
      api = {
        namespace = "frontend"
        sa_name   = "api"
      }
      worker = {
        namespace = "backend"
        sa_name   = "worker"
        extra_federated_subjects = {
          autoscaler = "system:serviceaccount:autoscaling:operator"
        }
      }
    }
  }

  assert {
    condition     = length(azurerm_user_assigned_identity.this) == 2
    error_message = "expected one UAMI per workload"
  }
  assert {
    condition     = length(azurerm_federated_identity_credential.this) == 2
    error_message = "expected one primary federation per workload"
  }
  assert {
    condition     = length(azurerm_federated_identity_credential.extra) == 1
    error_message = "expected one extra federation from extra_federated_subjects"
  }
  assert {
    condition     = azurerm_federated_identity_credential.this["api"].subject == "system:serviceaccount:frontend:api"
    error_message = "federation subject must derive from namespace + sa_name"
  }
  assert {
    condition     = azurerm_federated_identity_credential.extra["worker.autoscaler"].subject == "system:serviceaccount:autoscaling:operator"
    error_message = "extra federation subject must be passed through verbatim"
  }
}
