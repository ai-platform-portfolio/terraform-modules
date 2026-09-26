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

module "identity" {
  source = "../../modules/identity"

  resource_group_name = "example-rg"
  location            = "eastus"
  name_prefix         = "example"
  loc_short           = "eus"
  oidc_issuer_url     = "https://example.oidc.local/issuer"

  # v0.2.0: caller-defined workloads map (no hardcoded names/namespaces).
  workloads = {
    api = {
      namespace = "frontend"
      sa_name   = "api"
    }
    worker = {
      namespace = "backend"
      sa_name   = "worker"
      # Generalised extra-federation hook (e.g. an autoscaler operator pod).
      extra_federated_subjects = {
        autoscaler = "system:serviceaccount:autoscaling:operator"
      }
    }
  }

  tags = { environment = "example" }
}
