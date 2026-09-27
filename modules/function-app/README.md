# Function app

Linux Python 3.12 Functions with a dedicated runtime identity, existing-storage
integration and a caller-owned delegated subnet. Public HTTPS ingress supports
signed external webhooks; application code must authenticate each request.

The implemented hosting tier is Flex Consumption. Additional hosting tiers belong
in this module when needed, with tier-specific validation; there is no separate
tier-named module. Code packages are deployed separately through approved CI.

The owner confirmed Flex Consumption with ZIP deployment on 2026-09-27.
Docker is a preference when supported, not a reason to replace this hosting plan.
[Microsoft's deployment matrix](https://learn.microsoft.com/en-us/azure/azure-functions/functions-deployment-technologies)
requires package deployment for Flex. The code deployment workflow and package
validation live in ops-shared, whose required quality check exercises an incompatible
Docker request and the checked-in application configuration. See
[AI-15](https://linear.app/ai-platform-portfolio/issue/AI-15).

Exactly one deployment per storage account owns the shared host containers through
`create_host_containers = true`; other apps reuse them. Import existing containers
into that owner's state before applying if they already exist.

Pass additional role assignments as a map. Runtime storage access covers only the
created host/deployment containers and queues, not the Terraform state container.
Access to individual Key Vault secrets must be supplied explicitly. App settings contain secret references,
not secret values. This module does not change storage or vault network policies.

## Documentation and verification

Checked 2026-09-27 against AzureRM 4.81.0, matching the central provider lock:
[provider resource](https://github.com/hashicorp/terraform-provider-azurerm/blob/v4.81.0/website/docs/r/function_app_flex_consumption.html.markdown)
and [Microsoft Flex deployment guidance](https://learn.microsoft.com/en-us/azure/azure-functions/flex-consumption-how-to).
The module uses managed-identity deployment storage and inline subnet integration.
Code deployment uses `az functionapp deployment source config-zip` through approved CI,
with Linux dependencies built beforehand and basic publishing authentication disabled.

Provider validation rejected an unsupported `key_vault_reference_identity_id`
argument during development; the runtime instead reads secrets through its managed
identity. Validation also identified deprecated queue `storage_account_name`, which
was replaced with `storage_account_id`. Mock tests verify restricted storage access,
HTTPS ingress and the caller's subnet. A live PR plan and post-deployment evidence
remain required; these local checks do not establish that the service is deployed.
