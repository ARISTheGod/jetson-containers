# Contributing to jetson-containers

Thanks for contributing! This document explains the workflow expectations for both human and automated (AI) contributors.

Basic rules
- Read the canonical repository governance at `CONSTITUTION.md` before making changes.
- Do not commit secrets, credentials, or private keys. If a change requires secret material, use external secret stores and document the process in an issue.
- All substantive changes (code, CI, specs, docs) should include a short rationale and, when applicable, a minimal reproduction or test case.

AI-specific rules
- Automated agents MUST consult `CONSTITUTION.md` before proposing or applying changes.
- Agents should create or update spec artifacts (e.g., `spec-kit` files) and include a human-readable rationale in the PR description.
- Agents MUST NOT push secrets or private key material. If secret-like patterns are detected locally, stop and alert humans.

Local checks (recommended)
- Install and run pre-commit hooks: `pip install -r requirements.txt && pre-commit install` then `pre-commit run --all-files`.
- Run unit and smoke tests where available before opening a PR.

Pull request process
- Create a short-lived feature branch named `feat/<short-description>` or `fix/<short-description>`.
- Rebase onto latest `master` from upstream before opening a PR.
- In the PR description include: purpose, testing performed, and link to any relevant `specs` or `CONSTITUTION.md` section.

If you are an automated process and need guidance, open an issue and ping maintainers for approval prior to wide changes.

Thanks — maintainers
