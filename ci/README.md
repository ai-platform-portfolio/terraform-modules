# Central infrastructure

`ci/` is the deployment root for shared portfolio infrastructure. Modules live
under `modules/`; environment values live in `terraform.tfvars`. The initial
configuration preserves the existing UK South network. The owner-approved
`functions` subnet adds `10.50.3.0/26`, delegated to `Microsoft.App/environments`
for Flex Consumption. It is separate from the ACA and private-endpoint subnets.
Function integration uses `module.network.subnet_ids["functions"]`.
Every apply still requires explicit owner approval.

State remains in the existing Azure Storage backend, using the `central-devops.tfstate` key.
Backend names are supplied from Secrets at initialization. Backend authentication
uses Entra ID; no account key is needed.
Set `ARM_SUBSCRIPTION_ID` to the owning subscription before planning.

## Deployment workflow

Before pushing deployment changes, run `make preflight` from the repository root.
It runs workflow lint, local validation/tests, and read-only GitHub/Azure checks
for planning environment restrictions and the live federation credential. It
requires Actionlint, ShellCheck, Terraform, and authenticated `gh` and `az` CLIs
with the intended Azure subscription selected and the `ci` backend initialized.
The identity is resolved from the sensitive Terraform output without printing it.
A failure blocks readiness; obtain
approval for any remote repair before retrying. These checks cannot mint a GitHub
Actions token locally: after pushing, follow `gh pr checks <number> --watch` and
require a successful backend-connected plan before calling the change verified.

`.github/workflows/deploy.yml` runs on relevant merges to `main` and manual
dispatches from `main`. `.github/workflows/plan.yml` authenticates and runs a real
OpenTofu 1.12.3 plan for same-repository PRs using `central-plan`. Fork PRs do not receive
the deployment identity. All of these jobs use the same sandbox Owner MI; PR
planning is not a read-only identity boundary.

The PR job updates one bot comment with its head commit and collapsible plan.
Initialization or authentication errors post a failed preview and fail the check.
Plan values marked sensitive stay hidden; Azure IDs, configured backend identifiers,
storage-account names and Key Vault names are redacted before publishing. Raw plans
are deleted on the runner and never uploaded. Superseded runs cannot update the
current revision's comment. A success requires a real backend-connected plan.

PR previews use `opentofu.lock.hcl`, copied to the runner's active lock filename.
Main deployment still uses Terraform 1.12.2 and its existing lock; the read-only
preview does not migrate live state or change the deployment engine.

1. `plan` authenticates using GitHub OIDC and the `central-plan` environment.
   This environment has no reviewers, wait timer or branch restriction: PR and
   fresh main plans start without approval, including while an apply awaits review.
   Both jobs use the dedicated sandbox Owner identity, as approved by the owner.
   The plan command does not apply resources, but its identity is write-capable.
   Terraform takes a state lease during planning.
2. Review the Terraform plan log, commit and fingerprint in the run summary.
   No-change plans skip deployment. Saved plans stay on the temporary runner;
   no state or plan files are uploaded to GitHub artifacts.
3. After reviewing the plan, approve the apply job's `central-apply` request through
   **Review deployments** on that workflow run.
   The environment requires `michaela-links`, permits only `main`, and disables
   administrator bypass. Self-review remains enabled for the solo portfolio owner.
4. The apply job rejects a superseded commit and produces a fresh, locked plan.
   Its complete JSON fingerprint must match the reviewed plan, excluding only
   the generation timestamp. Drift or changed values require a new run and approval.
5. Apply executes that verified saved plan with Terraform state locking. A stale
   state causes Terraform to reject it. Failed applies require investigation and
   a new reviewed plan; there is no automatic rollback or unreviewed retry.

Only apply jobs are serialized; an active apply is not cancelled by a newer merge.
GitHub can replace an older pending apply with the newest pending apply. Planning
is independent of this queue and runs fresh on every relevant main push.

### Azure bootstrap

GitHub environments are configured. `module.deployment_identity` creates
`ai-platform-central-deployment` in `ai-platform-ci-rg`, with a plan and an apply
federation per entry in `github_repositories` in `github.auto.tfvars.json`. Adding a
repository extends that map, not the MI count. The control repository retains
its existing Terraform credential addresses to avoid replacement. The MI supports
at most ten repositories with this two-credential pattern. Its name has no regional
suffix; its Azure location is independent
of its subscription-wide deployment permissions. The old organisation's identity
is untouched.

Subscription Owner is an explicit sandbox decision. Storage Blob Data Contributor
on the existing `tfstate` container supplies state data-plane access; Owner alone
does not supply that access. This container also holds legacy state. Workload
identities should receive permissions appropriate to their individual workloads.

The initial local bootstrap created the identity and functions subnet. Federation
repairs require an explicitly approved bootstrap when CI authentication is broken.
Subsequent changes use this workflow and its deployment approval gate.

Store `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID` and `AZURE_CLIENT_ID` as
organization Actions secrets, granting access to this repository. Keep these
identifiers out of Actions Variables. Authentication
still uses OIDC; no Azure client secret or storage key is used.
After bootstrap, use the `deployment_client_id` Terraform output for the
organization secret; do not use the old organisation's client ID.
Store backend identifiers in organization secrets `TF_BACKEND_RESOURCE_GROUP`,
`TF_BACKEND_RESOURCE_NAME` (the storage account), `TF_BACKEND_CONTAINER` and
`TF_BACKEND_CONTAINER_SCOPE`. Grant this repository access to those secrets.
Storage-account and Key Vault names must not appear in tracked configuration or
documentation. Local bootstrap inputs live under ignored `.migration/` with
restricted permissions; saved Terraform plans and state still contain these values.
The federated subjects must be:

```
repo:ai-platform-portfolio@334196300/terraform-modules@1389557192:environment:central-plan
repo:ai-platform-portfolio@334196300/terraform-modules@1389557192:environment:central-apply
```

Issuer: `https://token.actions.githubusercontent.com`; audience:
`api://AzureADTokenExchange`. There is no per-branch or PR-context credential.
This explicitly trusts PR jobs with the shared Owner permissions, as chosen for
the sandbox. Keep the apply environment's required reviewer and main-only policy.
Azure federation provisioning requires an owner-approved Terraform bootstrap
plan; a repository merge does not provide that approval.

Before initialization, both planning jobs check required fields against GitHub's live
repository metadata and compares an actual GitHub-issued token's issuer, audience
and subject with the proposed plan environment trust. Tokens stay in memory and are not logged.
The JSON tfvars file is the same input consumed by Terraform and this check.

Mocked tests check the exact subjects and map expansion. They do not prove live
authentication. After bootstrap, the PR job must successfully exchange its token,
initialize the real backend and plan. The main jobs must also pass
authentication in their distinct environment context before deployment is called
verified. Never print OIDC tokens or persist them as artifacts.

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
