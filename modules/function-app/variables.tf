variable "name" { type = string }
variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "subnet_id" {
  description = "Existing delegated subnet; the caller owns network topology."
  type        = string
}
variable "storage" {
  type      = object({ id = string, name = string, blob_endpoint = string })
  sensitive = true
}
variable "app_settings" {
  type      = map(string)
  sensitive = true
  default   = {}
}
variable "role_assignments" {
  type      = map(object({ scope = string, role = string }))
  sensitive = true
}
variable "tags" {
  type    = map(string)
  default = {}
}
variable "queues" {
  type    = set(string)
  default = []
}
variable "create_host_containers" {
  description = "One owner per storage account creates the shared Azure Functions host containers."
  type        = bool
  default     = false
}
