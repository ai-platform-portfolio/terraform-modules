# v0.2.0: single map output keyed by the caller's workload handles, replacing
# the previous fixed per-workload outputs (upload_api / embedding_worker /
# retrieval_api / mcp_server). Consumers index this map by their own keys.
output "workloads" {
  description = "Map of provisioned workloads -> UAMI identifiers + the federated namespace/service-account."
  value = {
    for k, uami in azurerm_user_assigned_identity.this :
    k => {
      name         = uami.name
      id           = uami.id
      client_id    = uami.client_id
      principal_id = uami.principal_id
      namespace    = var.workloads[k].namespace
      sa_name      = var.workloads[k].sa_name
    }
  }
}
