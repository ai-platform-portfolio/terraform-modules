variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "name_prefix" { type = string }
variable "loc_short" { type = string }

# v0.2.0: containers, role assignments and lifecycle rules are all caller-defined.
# No solution-specific container names or prefixes baked into the module.

variable "containers" {
  description = "Blob containers to create. Neutral default [] — caller supplies names."
  type        = set(string)
  default     = []
}

variable "role_assignments" {
  description = "Role assignments to grant on the storage account, keyed by a stable logical name."
  type = map(object({
    principal_id         = string
    role_definition_name = string
  }))
  default = {}
}

variable "lifecycle_rules" {
  description = "Blob lifecycle management rules. Neutral default [] disables the management policy entirely."
  type = list(object({
    name                       = string
    prefix_match               = list(string)
    tier_to_cool_after_days    = optional(number)
    tier_to_archive_after_days = optional(number)
    delete_after_days          = optional(number)
  }))
  default = []
}

# --- Private networking (v0.2.0: real private endpoint, no facade) ---
variable "enable_private_endpoints" {
  description = "When true: disable public network access AND create a real blob private endpoint + DNS wiring."
  type        = bool
}

variable "private_endpoint_subnet_id" {
  description = "Subnet ID to host the blob private endpoint NIC. Required when enable_private_endpoints = true."
  type        = string
  default     = ""
}

variable "private_dns_zone_id" {
  description = "Private DNS zone ID (privatelink.blob.core.windows.net) for the private endpoint. Optional."
  type        = string
  default     = ""
}

variable "tags" {
  type    = map(string)
  default = {}
}
