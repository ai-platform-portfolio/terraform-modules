variable "network" {
  description = "Existing shared network; address allocations require owner approval."
  type = object({
    resource_group_name = string
    location            = string
    name                = string
    address_space       = list(string)
    subnets = map(object({
      name             = string
      address_prefixes = list(string)
      delegations = optional(map(object({
        service = string
        actions = list(string)
      })), {})
    }))
    private_dns_zones = map(string)
    tags              = optional(map(string), {})
  })
}

variable "deployment_identity" {
  type = object({
    resource_group_name = string
    name_prefix         = string
    location            = string
    roles = map(object({
      scope_suffix         = string
      role_definition_name = string
    }))
  })
}

variable "state_container_scope" {
  description = "Existing Terraform state container resource ID, supplied from a secret."
  type        = string
  sensitive   = true
}

variable "github_repositories" {
  description = "Repositories trusted by the shared CI identity; two credentials per repository."
  type = map(object({
    owner             = string
    owner_id          = string
    name              = string
    repository_id     = string
    apply_environment = string
  }))
  validation {
    condition     = contains(keys(var.github_repositories), "terraform-modules") && length(var.github_repositories) <= 10
    error_message = "Include the control repository terraform-modules and stay within the MI's 20-credential limit."
  }
}
