output "environment_id" {
  description = "ID of the Container App Environment."
  value       = azurerm_container_app_environment.this.id
}

output "environment_default_domain" {
  description = "Default domain of the Container App Environment (suffix for app FQDNs)."
  value       = azurerm_container_app_environment.this.default_domain
}

output "environment_static_ip_address" {
  description = "Static IP of the environment's load balancer (internal IP when internal_ingress_only)."
  value       = azurerm_container_app_environment.this.static_ip_address
}

# --- App outputs (null when workload_kind = "job") ---
output "container_app_id" {
  description = "ID of the Container App (null when workload_kind != 'app')."
  value       = local.is_app ? azurerm_container_app.this[0].id : null
}

output "container_app_name" {
  description = "Name of the Container App (null when workload_kind != 'app')."
  value       = local.is_app ? azurerm_container_app.this[0].name : null
}

output "latest_revision_fqdn" {
  description = "FQDN of the latest app revision (null when not an app or ingress disabled)."
  value       = local.is_app ? azurerm_container_app.this[0].latest_revision_fqdn : null
}

# --- Job outputs (null when workload_kind = "app") ---
output "job_id" {
  description = "ID of the Container App Job (null when workload_kind != 'job')."
  value       = local.is_job ? azurerm_container_app_job.this[0].id : null
}

output "job_name" {
  description = "Name of the Container App Job (null when workload_kind != 'job'). Start an execution with `az containerapp job start`."
  value       = local.is_job ? azurerm_container_app_job.this[0].name : null
}

# --- Kind-agnostic convenience output ---
output "workload_name" {
  description = "Name of the created workload (app or job)."
  value       = local.workload_name
}
