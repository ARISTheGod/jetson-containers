# Constitution for jetson-containers

This is the canonical AI/Human governance document for the repository. It mirrors AI_CONSTITUTION.md and is preferred by agent frameworks that look for `CONSTITUTION.md`.

## Principles

1. Transparency
   - Track all AI-led and human-led changes with clear rationale and spec artifacts.

2. Reproducibility
   - Commands, requirements, and workflows must be recorded in code and docs.

3. Separation of concerns
   - No secret management in code. Config and credentials are externalized.

4. Least-privilege and auditability
   - No secrets in spec or archive artifacts.

5. Safety-first
   - Fail early on policy violations and high-risk changes.

## Policy enforcement

- `scripts/normalize-constitution.sh` ensures `CONSTITUTION.md` exists and points the same content as `AI_CONSTITUTION.md`.
- `spec-kit-runner.sh` and CI run secret scanning and archive retention.
- Prefer `CONSTITUTION.md` for AI agent compatibility; `AI_CONSTITUTION.md` is an alias.
