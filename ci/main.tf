module "network" {
  source = "../modules/network"

  resource_group_name = var.network.resource_group_name
  location            = var.network.location
  name                = var.network.name
  address_space       = var.network.address_space
  subnets             = var.network.subnets
  private_dns_zones   = var.network.private_dns_zones
  tags                = var.network.tags
}

data "azurerm_subscription" "current" {}

locals {
  github_subject_prefix = "repo:ai-platform-portfolio@334196300/terraform-modules@1389557192:environment"
}

module "deployment_identity" {
  source = "../modules/identity"

  create_resource_group = true
  resource_group_name   = var.deployment_identity.resource_group_name
  location              = var.deployment_identity.location
  name_prefix           = var.deployment_identity.name_prefix
  oidc_issuer_url       = "https://token.actions.githubusercontent.com"
  workloads = {
    central-deployment = {
      federated_subject = "${local.github_subject_prefix}:central-plan"
      extra_federated_subjects = {
        apply = "${local.github_subject_prefix}:central-apply"
      }
    }
  }
  role_assignments = {
    for key, role in var.deployment_identity.roles : key => {
      workload             = "central-deployment"
      scope                = key == "state" ? var.state_container_scope : "${data.azurerm_subscription.current.id}${role.scope_suffix}"
      role_definition_name = role.role_definition_name
    }
  }
}
