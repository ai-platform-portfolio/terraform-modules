variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "name_prefix" { type = string }
variable "loc_short" { type = string }
variable "embedding_capacity" { type = number }
variable "chat_capacity" { type = number }

# v0.2.0: caller supplies the set of principals to grant the OpenAI User role,
# replacing the two fixed worker_/retrieval_ principal vars.
variable "openai_user_principal_ids" {
  description = "Set of principal IDs to grant 'Cognitive Services OpenAI User'. Neutral default []."
  type        = set(string)
  default     = []
}

# --- Private networking (v0.2.0: real private endpoint, no facade) ---
variable "enable_private_endpoints" {
  description = "When true: disable public network access AND create a real private endpoint + DNS wiring for the account."
  type        = bool
}

variable "private_endpoint_subnet_id" {
  description = "Subnet ID to host the OpenAI private endpoint NIC. Required when enable_private_endpoints = true."
  type        = string
  default     = ""
}

variable "private_dns_zone_id" {
  description = "Private DNS zone ID (privatelink.openai.azure.com) for the private endpoint. Optional."
  type        = string
  default     = ""
}

variable "tags" {
  type    = map(string)
  default = {}
}
