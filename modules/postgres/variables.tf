variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "name_prefix" { type = string }
variable "loc_short" { type = string }
variable "sku_name" { type = string }
variable "storage_mb" { type = number }
variable "tenant_id" { type = string }
variable "aad_admin_object_id" { type = string }
variable "aad_admin_principal_name" { type = string }
variable "aad_admin_principal_type" { type = string }
variable "ci_admin_object_id" {
  type    = string
  default = ""
}
variable "ci_admin_principal_name" {
  type    = string
  default = ""
}

variable "workload_admins" {
  description = "Per-workload UAMI principals to also register as Microsoft Entra admins."
  type = map(object({
    object_id      = string
    principal_name = string
  }))
  default = {}
}

# --- Database (v0.2.0: required, no solution-coupled default) ---
variable "database_name" {
  description = "Name of the application database to create on the server. REQUIRED — the module no longer ships a solution-specific default."
  type        = string
}

variable "database_charset" {
  description = "Charset for the created database."
  type        = string
  default     = "UTF8"
}

variable "database_collation" {
  description = "Collation for the created database."
  type        = string
  default     = "en_US.utf8"
}

variable "server_extensions" {
  description = "Postgres extensions to allowlist via azure.extensions (e.g. [\"VECTOR\"]). Empty list disables the configuration entirely — neutral default."
  type        = list(string)
  default     = []
}

# --- Private networking (v0.2.0: real private endpoint, no facade) ---
variable "enable_private_endpoints" {
  description = "When true: disable public network access AND create a real private endpoint + DNS wiring (requires private_endpoint_subnet_id)."
  type        = bool
}

variable "private_endpoint_subnet_id" {
  description = "Subnet ID to host the Postgres private endpoint NIC. Required when enable_private_endpoints = true."
  type        = string
  default     = ""
}

variable "private_dns_zone_id" {
  description = "Private DNS zone ID (privatelink.postgres.database.azure.com) to register the private endpoint A records into. Optional; when empty no DNS zone group is created."
  type        = string
  default     = ""
}

variable "tags" {
  type    = map(string)
  default = {}
}
