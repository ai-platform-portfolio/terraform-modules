# Network migration validation

Prepared on 2026-09-26 from `localtfsa/tfstate/auth0.tfstate`, serial 14,
using Terraform 1.12.2 and AzureRM 4.81.0.

- Ten network instances moved into `module.network` in local state copies.
- All managed resource IDs and attributes preserved across the split.
- Nine legacy managed instances and four data sources preserved, including Auth0
  and Key Vault entries. No secret values were printed or committed.
- A refreshed Azure plan against the local network state returned exit code 0:
  no creates, updates, deletes or replacements; output values also unchanged.
- `central-devops.tfstate` did not exist at inspection. No remote state was written.

This is evidence of preparation, not completion. Recheck source ETag/serial and
destination absence immediately before publishing the split. Local state backups,
ETag metadata and saved plan are access-restricted under ignored `.migration/`.
