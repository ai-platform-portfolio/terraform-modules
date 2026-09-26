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
      terraform-modules-plan  = "repo:ai-platform-portfolio@334196300/terraform-modules@1389557192:environment:central-plan"
      terraform-modules-apply = "repo:ai-platform-portfolio@334196300/terraform-modules@1389557192:environment:central-apply"
    }
    error_message = "Trust exactly the plan and apply environments, without PR or branch credentials."
  }
}

run "another_repository_reuses_the_identity" {
  command = plan

  variables {
    github_repositories = {
      terraform-modules = {
        owner = "example", owner_id = "123", name = "terraform-modules", repository_id = "456", plan_environment = "central-plan", apply_environment = "central-apply"
      }
      workload = {
        owner = "example", owner_id = "123", name = "workload", repository_id = "789", plan_environment = "plan", apply_environment = "deploy"
      }
    }
  }

  assert {
    condition     = length(local.github_subjects) == 4 && length(module.deployment_identity.workloads) == 1 && local.github_subjects["workload-plan"] == "repo:example@123/workload@789:environment:plan" && local.github_subjects["workload-apply"] == "repo:example@123/workload@789:environment:deploy"
    error_message = "Adding a repository must add exactly two subjects without adding another managed identity."
  }
}
