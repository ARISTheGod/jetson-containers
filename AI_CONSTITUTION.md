# AI Constitution for jetson-containers

This document defines principles for AI-driven modifications, spec-driven development, and secure artifact management in this repository.

## Principles

1. Transparency
   - All AI changes must be documented with a spec and rationale in `docs/spec-kit.md`.
   - No silent modifications to secrets, credentials, or private keys.

2. Reproducibility
   - Each automation workflow must be repeatable using the same command and dependencies.
   - Build artifacts must be generated from source code and state described in the spec.

3. Separation of concerns
   - Build scripts and configuration scripts must not directly store user secrets or tokens.
   - Workflows must isolate sensitive data by using temporary directories and explicit sanitize checks.

4. Least privilege and auditability
   - Workflows should not expose runtime secrets in logs.
   - `specs-archive` rotation policy keeps only the latest 10 archives and purges older artifacts.

5. Safety-first
   - If secret patterns are detected in generated spec outputs, the run must fail and delete the candidate archive.
   - Private key material (RSA/ED25519/etc.) must never remain in archived data.

## AI compatiblity

- For every new file or feature, follow the spec-driven workflow:
  1. `spec-kit.constitution`
  2. `spec-kit.specify`
  3. `spec-kit.plan`
  4. `spec-kit.tasks`
  5. `spec-kit.implement`

- For repository-wide guardrails, ensure all changes pass the `spec-kit` check and render no leaked sensitive tokens.

- Keep compatibility with AI tooling by using plain-text, explicit file names and locations:
  - JSON/YAML config at `packages/**` and `jetson_containers/**`
  - CI templates in `.github/workflows/`
  - docs in `docs/`

- Avoid tool-specific vendor lock-in in repository ownership.
