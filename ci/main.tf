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
  github_subjects = merge([
    for name, repo in var.github_repositories : {
      "${name}-pr"    = "repo:${repo.owner}@${repo.owner_id}/${repo.name}@${repo.repository_id}:pull_request"
      "${name}-apply" = "repo:${repo.owner}@${repo.owner_id}/${repo.name}@${repo.repository_id}:environment:${repo.apply_environment}"
    }
  ]...)
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
      federated_subject = local.github_subjects["terraform-modules-pr"]
      extra_federated_subjects = {
        for key, subject in local.github_subjects : (key == "terraform-modules-apply" ? "apply" : key) => subject
        if key != "terraform-modules-pr"
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
