variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "name_prefix" { type = string }
variable "loc_short" { type = string }
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
    namespace                = string
    sa_name                  = string
    extra_federated_subjects = optional(map(string), {})
  }))
  default = {}
}

variable "tags" {
  type    = map(string)
  default = {}
}
