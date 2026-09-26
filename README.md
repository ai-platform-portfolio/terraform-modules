# Terraform modules

Reusable modules for `ai-platform-portfolio`. This repository has no environment
deployment root or live state. See [modules](modules/README.md) and
[provenance](PROVENANCE.md).

Consumers use `git::https://github.com/ai-platform-portfolio/terraform-modules.git//modules/<name>?ref=<full-commit-sha>`.
Upgrade the pinned commit in a reviewed consumer change. Private repository
authentication must be available to the caller; no token belongs in a source URL.

Run `make check` with Terraform 1.12.2 and Python 3.11+ installed. It checks
formatting, initialises providers without a backend, and validates every module
and example. `make test` also runs the supplied mocked-provider plan tests.
Neither command applies resources or needs cloud credentials.

Module interface and resource-address changes require review of consumer impact.
Migrating existing addresses requires explicit moved blocks and a reviewed plan.
This initial copy does not redesign networking or expand module capabilities.
