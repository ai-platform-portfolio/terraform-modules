variable "function_storage" {
  description = "Existing storage identifiers supplied from GitHub Secrets."
  type        = object({ name = string, resource_group_name = string })
  sensitive   = true
}

variable "function_vault" {
  description = "Existing vault reference supplied from GitHub Secrets; no secret values."
  type        = object({ name = string, id = string })
  sensitive   = true
}

variable "function_apps" {
  type = map(object({
    name                   = string
    create_host_containers = optional(bool, false)
    queues                 = set(string)
    secret_names           = set(string)
    settings               = map(string)
    source                 = object({ repository = string, revision = string, path = string, format = string })
  }))
  validation {
    condition     = alltrue([for app in var.function_apps : app.source.format == "zip"])
    error_message = "The implemented Flex Consumption host requires ZIP packages; custom container images are unsupported."
  }
}
