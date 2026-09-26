mock_provider "azurerm" {
  mock_data "azurerm_subscription" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000"
    }
  }
}

variables {
    state_container_scope = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.Storage/storageAccounts/test/blobServices/default/containers/state"
}

run "github_subject_matches_observed_repository_claim" {
  command = plan

  assert {
    condition = local.github_subjects == {
      terraform-modules-pr    = "repo:ai-platform-portfolio@334196300/terraform-modules@1389557192:pull_request"
      terraform-modules-apply = "repo:ai-platform-portfolio@334196300/terraform-modules@1389557192:environment:central-apply"
    }
    error_message = "Trust exactly the immutable PR context and apply environment, with no branch or plan-environment credential."
  }
}

run "another_repository_reuses_the_identity" {
  command = plan

  variables {
    github_repositories = {
      terraform-modules = {
        owner = "example", owner_id = "123", name = "terraform-modules", repository_id = "456", apply_environment = "central-apply"
      }
      workload = {
        owner = "example", owner_id = "123", name = "workload", repository_id = "789", apply_environment = "deploy"
      }
    }
  }

  assert {
    condition = length(local.github_subjects) == 4 && length(module.deployment_identity.workloads) == 1 && local.github_subjects["workload-pr"] == "repo:example@123/workload@789:pull_request" && local.github_subjects["workload-apply"] == "repo:example@123/workload@789:environment:deploy"
    error_message = "Adding a repository must add exactly two subjects without adding another managed identity."
  }
}
