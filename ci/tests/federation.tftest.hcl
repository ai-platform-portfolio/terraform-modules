mock_provider "azurerm" {
  mock_data "azurerm_subscription" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000"
    }
  }
}

run "github_subject_matches_observed_repository_claim" {
  command = plan

  variables {
    state_container_scope = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.Storage/storageAccounts/test/blobServices/default/containers/state"
  }

  assert {
    condition     = "${local.github_subject_prefix}:central-plan" == "repo:ai-platform-portfolio@334196300/terraform-modules@1389557192:environment:central-plan"
    error_message = "GitHub's observed subject includes owner and repository IDs; name-only federation cannot authenticate."
  }
}
