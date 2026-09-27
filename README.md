# Terraform modules

Reusable modules, examples and tests for `ai-platform-portfolio`. Live deployment
roots and pipelines belong in implementation repositories, including
[ops-shared/ci](https://github.com/ai-platform-portfolio/ops-shared/tree/main/ci)
for central infrastructure. Deploying from this repository requires an explicit,
specific owner exception; the former `ci/` exception is withdrawn.
See [modules](modules/README.md) and
[provenance](PROVENANCE.md).

Consumers use `git::https://github.com/ai-platform-portfolio/terraform-modules.git//modules/<name>?ref=<full-commit-sha>`.
Upgrade the pinned commit in a reviewed consumer change. Private repository
authentication must be available to the caller; no token belongs in a source URL.

Run `make check` with Terraform 1.12.2 and Python 3.11+ installed. It checks
formatting, initialises providers without a backend, and validates every module
and example. `make test` also runs the supplied mocked-provider plan tests.
Neither command applies resources or needs cloud credentials.
Validation rejects Terraform roots outside `modules/` and `examples/` before
running Terraform; an acceptance fixture verifies that a new `ci/main.tf` fails.

Module interface and resource-address changes require review of consumer impact.
Migrating existing addresses requires explicit moved blocks and a reviewed plan.
The network migration preserves existing Azure resources and address allocations.
