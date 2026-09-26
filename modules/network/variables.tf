variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "name" { type = string }
variable "address_space" { type = list(string) }

variable "subnets" {
  type = map(object({
    name             = string
    address_prefixes = list(string)
    delegations = optional(map(object({
      service = string
      actions = list(string)
    })), {})
  }))
}

variable "private_dns_zones" { type = map(string) }

variable "tags" {
  type    = map(string)
  default = {}
}
