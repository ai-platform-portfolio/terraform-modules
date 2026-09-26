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
