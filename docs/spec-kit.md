# Spec Kit Integration for jetson-containers

This document explains how we run GitHub Spec Kit in this repository, with security-first constraints and archive retention.

## Goals

- Fully support `github/spec-kit` usage in an existing project (brownfield).  
- Ensure no private keys, secrets or credentials are stored in generated artifacts.  
- Keep only the latest 10 rounds in `specs-archive/`.

## Files added

- `scripts/spec-kit-runner.sh`: wrapper to run spec-kit commands in isolated, temporary directory with scanning and critical retention.
- `.github/workflows/spec-kit.yml`: scheduled and manual workflow to run the runner and upload results.
- `AI_CONSTITUTION.md` and `CONSTITUTION.md`: project-level AI safety & compatibility policy (canonical agent filename is `CONSTITUTION.md`).

## Usage

1. Install dependencies on the runner:

   ```bash
   python3 -m pip install --upgrade --user uv spec-kit
   ```

2. Run runner manually:

   ```bash
   ./scripts/spec-kit-runner.sh all
   ```

3. Check `specs-archive/` for archives.

4. Confirm no secrets exist in output before creating release.

## Archive retention policy

- `spec-kit-runner` puts output into `specs-archive/spec-kit-output-<timestamp>.tar.gz`.
- Keeps at most 10 archives in `specs-archive/`; older archives are auto-deleted.

## Secret sanitization

`spec-kit-runner.sh` checks generated files for patterns matching:
- AWS keys (`AKIA`, `ASIA`)
- Google keys (`AIza`, `ya29`)
- common API key labels (`secret`, `password`, `token`, `api_key`)
- private key blocks (`BEGIN PRIVATE KEY`, `BEGIN RSA PRIVATE KEY`)

If any matches are found, run exits non-zero.

## Issues & debugging

- To debug artifacts from workflow runs: review workflow log on GitHub Actions, and the uploaded artifact (specs-archive).  
- For `ollama` or `llama-factory` build failures, inspect `logs/` and ensure the following are not causing failure conditions:
  - `ln: /etc/resolv.conf` resource busy
  - `Failed to open connection to "system" message bus`
  - Locale warnings (safe to ignore).  

## Next steps (improvement roadmap)

- Add dedicated `specs-archive` hashed metadata and signed provenance file.
- Add `gitleaks` or `detect-secrets` CI scan job for outputs in `specs-archive/`.
- Add quality checks for `spec-kit` files to integrate with `jetson_containers` package dependencies automatic discovery.
