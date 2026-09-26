# Shared Terraform modules

Reusable Azure building-block modules for the `ai-platform-portfolio` repos. These
are the **single source of truth** — consuming repos reference them via a
git-subdirectory source pinned to a full commit SHA, rather than copying modules per repo
(centralise-don't-copy).

## Consuming a module

```hcl
module "postgres" {
  source = "git::https://github.com/ai-platform-portfolio/terraform-modules.git//modules/postgres?ref=<full-commit-sha>"

  # v0.2.0: solution-specific values are REQUIRED inputs, not module defaults.
  database_name     = "myapp"
  server_extensions = ["VECTOR"] # opt-in; default [] leaves the server stock

  # Real private endpoint (no facade): wire to the shared network outputs.
  enable_private_endpoints   = true
  private_endpoint_subnet_id = module.shared_network.private_endpoint_subnet_id
  private_dns_zone_id        = module.shared_network.private_dns_zone_ids["postgres"]
  # ...remaining inputs
}
```

Only the **invocation** (wiring + tfvars) lives in the consuming repo; the
module definition lives here. See `../examples/` for full neutral-value
invocations of each changed module, and `../PROVENANCE.md` for the v0.2.0
breaking interface changes (required `database_name`, map-based identity
`workloads`, parameterised storage containers/roles/lifecycle, the
`openai_user_principal_ids` set, and real private endpoints).

## Modules

| Module | Purpose |
|--------|---------|
| `auth0` | Auth0 resource servers (APIs), clients (incl. M2M), grants, KV secret sync |
| `identity` | User-assigned managed identities + OIDC federation for workloads |
| `storage` | Storage account + role assignments for workload principals |
| `postgres` | Postgres flexible server (+ replica) with Entra admin registration |
| `openai` | Azure OpenAI account + model deployments + role assignments |
| `aks-nodepool` | Spot user node pool attached to a shared AKS cluster |
| `aca` | Azure Container Apps + Environment — a Container **App** or a run-to-completion **Job** (`workload_kind`); VNet-integrated, internal-only, KV secrets + ACR pull via a user-assigned identity |

## Versioning

Tag releases as `tf-modules-vX.Y.Z`. Consumers pin to a full commit SHA; bump the pin
deliberately. Modules are parameterised — no identifying values are hardcoded.
