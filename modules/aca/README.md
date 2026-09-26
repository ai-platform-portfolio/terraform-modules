# aca module

Azure **Container Apps** on a shared **Container App Environment**, shaped for
the portfolio: VNet-integrated, optionally internal-only (no public ingress),
with secrets sourced from Key Vault and registry auth via a **user-assigned
managed identity** the caller owns. One module, **two workload kinds**:

- `workload_kind = "app"` (default) — a long-running **Container App** (ingress,
  scale-to-zero, custom scale rules).
- `workload_kind = "job"` — an on-demand **Container App Job** for an
  episodic/batch **run-to-completion** workload (container runs once and exits).

Like every module here the body carries **no** solution-specific or identifying
literals — image, registry, secrets, subnet/DNS/identity IDs are all inputs.

## App vs Job — pick the right primitive

Choose **`job`** when the container does a unit of work and exits (a batch/cron
run, a one-shot investigation). A scale-to-zero App with no ingress would deploy
green but **never wake** — a facade; the Job's manual trigger lets an operator
actually start (and smoke-test) a real execution:

```
az containerapp job start --name <job_name> --resource-group <rg>
```

Choose **`app`** for a service that must stay reachable (HTTP ingress) or
autoscale on load/events.

## What it creates

| Resource | When | Notes |
|----------|------|-------|
| `azurerm_container_app_environment.this` | always | VNet-integrated when `infrastructure_subnet_id` set; internal LB when `internal_ingress_only`; Consumption-only unless `workload_profiles` given; optional Log Analytics + zone redundancy. |
| `azurerm_container_app.this` | `workload_kind = "app"` | Single-revision app; `UserAssigned` identity; optional ACR `registry` (MI auth); KV-backed `secret` blocks (MI auth); `template` with scale-to-zero (`min_replicas` default 0) + optional `custom_scale_rule`s; optional HTTP `liveness_probe`/`readiness_probe` (`liveness_probe_path` / `readiness_probe_path`, served on `ingress_target_port`; empty = ACA's TCP default); optional internal/external `ingress`. |
| `azurerm_container_app_job.this` | `workload_kind = "job"` | `manual_trigger_config` (on-demand), `replica_timeout_in_seconds` / `replica_retry_limit`; same `UserAssigned` identity + ACR `registry` + KV-backed `secret` + `env` wiring as the app, run to completion. |

## Identity, secrets & registry (managed-identity, no stored creds)

The module does **not** create the managed identity or its role assignments —
the caller creates a UAMI and grants it `AcrPull` on the registry and
`Key Vault Secrets User` on the vault, then passes `user_assigned_identity_id`.
That keeps registry/KV scopes (identifying resource IDs) out of the shared
module body. The app then:

- authenticates to ACR with the UAMI (`registry.identity`),
- resolves each `secrets[*].key_vault_secret_id` through the UAMI at runtime,
- exposes them as env vars via `secret_env_vars` (`ENV_NAME => secret name`).

## Private networking

This module uses **VNet integration** (`infrastructure_subnet_id`, delegated to
`Microsoft.App/environments`) plus an **internal load balancer**
(`internal_ingress_only = true`) for the no-public-ingress posture — Container
Apps are fronted this way rather than by a private endpoint. It therefore does
**not** declare an `enable_private_endpoints` flag, so the repo's `anti-facade`
policy rule does not apply here (that rule only governs modules that expose the
flag). Datastores in the same solution (postgres/storage) supply the real
private endpoints.

## Consume

```hcl
module "aca" {
  source = "git::https://github.com/ai-platform-portfolio/terraform-modules.git//modules/aca?ref=<full-commit-sha>"

  resource_group_name = azurerm_resource_group.app.name
  location            = "uksouth"
  name_prefix         = "myapp"
  loc_short           = "uks"

  # VNet-integrated, no public ingress, scale-to-zero.
  infrastructure_subnet_id = data.terraform_remote_state.shared.outputs.aca_subnet_id
  internal_ingress_only    = true
  min_replicas             = 0
  max_replicas             = 1

  image                     = var.image            # <acr>.azurecr.io/<repo>:<tag>
  registry_server           = var.registry_server  # <acr>.azurecr.io
  user_assigned_identity_id = azurerm_user_assigned_identity.app.id

  secrets = [
    { name = "anthropic-api-key", key_vault_secret_id = azurerm_key_vault_secret.anthropic.versionless_id },
  ]
  secret_env_vars = { ANTHROPIC_API_KEY = "anthropic-api-key" }
  env_vars        = { SEC_EDGAR_USER_AGENT = var.edgar_user_agent }
}
```

For the **job** variant, set `workload_kind = "job"` and (optionally) the
trigger sizing — everything else is identical:

```hcl
module "aca" {
  source = "git::https://github.com/ai-platform-portfolio/terraform-modules.git//modules/aca?ref=<full-commit-sha>"

  workload_kind = "job"
  # ...same resource_group_name / location / name_prefix / loc_short,
  #    infrastructure_subnet_id / internal_ingress_only, image / registry_server,
  #    user_assigned_identity_id, secrets / secret_env_vars / env_vars...

  job_replica_timeout_in_seconds = 1800
  job_replica_retry_limit        = 1
  job_parallelism                = 1
  job_replica_completion_count   = 1
}
```

Grant the UAMI its roles in the caller (`AcrPull` + `Key Vault Secrets User`)
and add `depends_on = [<the KV role assignment>]` to the module block so the
first execution/revision can read the secrets on create.

## App scale-to-zero note

For `workload_kind = "app"`, `min_replicas = 0` with **no ingress** means
nothing wakes the app on its own — add an event source under
`custom_scale_rules` (cron / azure-queue / azure-servicebus), or use
`workload_kind = "job"` if the work is episodic and run-to-completion (the
common case for a batch/one-shot agent).
