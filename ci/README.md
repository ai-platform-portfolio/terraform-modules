# Central infrastructure

`ci/` is the deployment root for shared portfolio infrastructure. Modules live
under `modules/`; environment values live in `terraform.tfvars`. The initial
configuration preserves the existing UK South network. The owner-approved
`functions` subnet adds `10.50.3.0/26`, delegated to `Microsoft.App/environments`
for Flex Consumption. It is separate from the ACA and private-endpoint subnets.
Function integration uses `module.network.subnet_ids["functions"]`.
Every apply still requires explicit owner approval.

State remains in `localtfsa/tfstate`, using the `central-devops.tfstate` key.
The storage resource group's old organisation name is an Azure name, not a
GitHub dependency. Backend authentication uses Entra ID; no account key is needed.
Set `ARM_SUBSCRIPTION_ID` to the owning subscription before planning.

## Network ownership migration

Completed on 2026-09-26; see [validation evidence](migrations/VALIDATION.md).
The procedure below records the transfer and recovery requirements, not a task
to rerun against the migrated state.

Source: `claudeaiportfolio/portfolio-infra` at
`67f2200b8537ff548206340ff423d4736b587a0f`, `terraform/network.tf`.
Its network resources share `auth0.tfstate` with Auth0. Do not point this root
at that state or copy the whole state into a second active backend.

The address mapping is in `migrations/network.json`. Preparation moves ten
network instances into `module.network`, preserving Azure IDs and attributes.
Auth0 resources and data sources remain in the legacy state. Existing network
outputs remain there as compatibility snapshots; future consumers must read
the new root's outputs or Azure data sources because those snapshots will not update.

1. Freeze all writers to the legacy root. Remove its network declarations and
   replace network outputs with data lookups before permitting another apply.
   The decommissioned source must not be used to deploy its old configuration.
2. Download an access-restricted backup of `auth0.tfstate` into `.migration/`.
   Record its ETag and serial. Confirm the destination blob does not exist.
3. Run `python3 scripts/prepare_network_migration.py .migration/original.tfstate .migration/split`.
   This only edits local copies; it checks preservation of resource attributes,
   distinct state lineages, and unchanged legacy resources/data sources.
4. Validate a refreshed plan against the prepared network state using a local
   backend copy of this root. Require zero creates, updates, deletes or replacements.
   Recheck the source ETag before publishing; changed state means prepare again.
5. Obtain explicit approval for remote state writes. Publish the destination
   before the reduced source, with all deployment writers frozen. Verify the
   destination before removing ownership from the source, then verify both.

Two state writes are not atomic. If the second fails, keep writers frozen: the
states temporarily claim the same network. Reconcile against the downloaded
backup before retrying. Rollback requires restoring source ownership and removing
destination ownership without destroying resources, with fresh approval; do not
blindly overwrite a state that has changed. Never use `state push -force` as a shortcut.

No migration command is run in CI. Never attach state files or saved plans to
PRs or workflow artifacts. Backend-free validation and mocked tests need no secrets.
