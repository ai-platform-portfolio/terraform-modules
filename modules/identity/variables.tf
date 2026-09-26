variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "name_prefix" { type = string }
variable "loc_short" {
  type    = string
  default = ""
}
variable "oidc_issuer_url" { type = string }

# v0.2.0: workloads are fully caller-defined. The module no longer hardcodes
# any solution-specific workload names, namespaces or service accounts.
#
# Each entry creates a user-assigned managed identity federated to a
# Kubernetes ServiceAccount (namespace + sa_name). The map key is a stable
# logical handle used to build the UAMI name and to look up outputs.
#
# extra_federated_subjects lets one UAMI be federated to ADDITIONAL
# ServiceAccount subjects (the generalised form of the old KEDA-operator
# special case): map of arbitrary label => full "system:serviceaccount:NS:SA"
# subject string.
variable "workloads" {
  description = "Map of workloads to provision UAMIs + OIDC federation for. Neutral default {} — caller supplies all names/namespaces."
  type = map(object({
    namespace                = optional(string)
    sa_name                  = optional(string)
    federated_subject        = optional(string)
    extra_federated_subjects = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for workload in values(var.workloads) : workload.federated_subject != null ?
      trimspace(workload.federated_subject) != "" :
      try(trimspace(workload.namespace) != "" && trimspace(workload.sa_name) != "", false)
    ])
    error_message = "Each workload needs a federated_subject or both namespace and sa_name."
  }
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "create_resource_group" {
  description = "Create the identity resource group when it is owned by this deployment."
  type        = bool
  default     = false
}

variable "role_assignments" {
  type = map(object({
    workload             = string
    scope                = string
    role_definition_name = string
  }))
  default = {}
}
