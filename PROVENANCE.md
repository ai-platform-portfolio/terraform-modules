# Module provenance

Copied with the repository owner's authorisation from
`claudeaiportfolio/portfolio-infra` at commit
`67f2200b8537ff548206340ff423d4736b587a0f`.

Included: `terraform/modules/` and `examples/`. Module-relative dependencies
were inspected; no external templates or scripts were referenced.
No environment configuration, state, secrets or environment tfvars were copied.

The source snapshot has no LICENSE file. This private copy does not introduce
an open-source licence or grant redistribution rights. Existing attribution is retained.

Migration changes are limited to repository/example paths and formatting.
Module inputs, resource names and behaviour are preserved. Existing comments
and interfaces are not retrospectively rewritten to satisfy new policies.

Backend-free validation passed for all seven modules and five examples using
Terraform 1.12.2. All 13 supplied mocked plan tests passed. Provider selections
are recorded in validation lock files; no live infrastructure was contacted.

The shared network from `terraform/network.tf` at the same source revision is
now represented by `modules/network` and composed in `ci/`. Its subnet and DNS
resources use maps; existing names and allocations are preserved in `ci/terraform.tfvars`.
See `ci/README.md` for the separate state-ownership migration and approval gates.
