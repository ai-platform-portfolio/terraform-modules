# Examples (validate-only)

Production-shaped invocations of the v0.2.0 modules with **neutral** example
values (no solution-specific or identifying data). These are wired for
`terraform init -backend=false && terraform validate` in CI — they are NOT
applied and intentionally use placeholder resource IDs.

Each example demonstrates the new v0.2.0 interface: required `database_name`,
the `workloads` map, parameterised storage containers/role-assignments, the
`openai_user_principal_ids` set, and the real (non-facade) private-endpoint
wiring driven by `enable_private_endpoints` + subnet/DNS-zone IDs.
