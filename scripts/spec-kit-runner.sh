#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# spec-kit-runner.sh
# A safety-first runner for running GitHub Spec Kit in this repository.
# It performs:
#   - installation of spec-kit and optional uv tool
#   - temporary workspace execution
#   - secret-sensitive sanitation of generated output
#   - archive retention (keep latest 10 in specs-archive)
#   - cleanup on exit

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ARCHIVE_DIR="${SPEC_ARCHIVE_DIR:-${REPO_ROOT}/specs-archive}"
TMP_WORKDIR="$(mktemp -d "${TMPDIR:-/tmp}/spec-kit-runner.XXXXXXXX")"
SPECKIT_VERSION="latest"

function die() {
  echo "[spec-kit-runner][ERROR] $*" >&2
  exit 1
}

function cleanup() {
  local rc=$?
  echo "[spec-kit-runner] cleaning up temporary directory: ${TMP_WORKDIR}"
  rm -rf "${TMP_WORKDIR}" || true
  return $rc
}
trap cleanup EXIT INT TERM

echo "[spec-kit-runner] repo root: ${REPO_ROOT}"
mkdir -p "${ARCHIVE_DIR}"

cd "${REPO_ROOT}"

if ! command -v python3 >/dev/null 2>&1; then
  die "python3 is required but not found"
fi

if ! python3 -m pip --version >/dev/null 2>&1; then
  echo "[spec-kit-runner] installing pip via get-pip.py"
  curl -fsSL https://bootstrap.pypa.io/get-pip.py | python3 - || die "failed to install pip"
fi

echo "[spec-kit-runner] installing spec-kit dependencies"
python3 -m pip install --upgrade --user uv spec-kit "${SPECKIT_VERSION}" || die "failed to install spec-kit"

if ! command -v spec-kit >/dev/null 2>&1; then
  # Some installs provide tool name specify; support both
  if command -v specify >/dev/null 2>&1; then
    export PATH="$(dirname "$(command -v specify)"):$PATH"
    ln -sf "$(command -v specify)" "${TMP_WORKDIR}/spec-kit"
    PATH="${TMP_WORKDIR}:$PATH"
  else
    die "spec-kit executable not found after install"
  fi
fi

echo "[spec-kit-runner] using spec-kit from $(command -v spec-kit)"

# Set strict workspace roots and avoid leak of secrets into environment
unset GITHUB_TOKEN GH_TOKEN AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN GOOGLE_APPLICATION_CREDENTIALS

# ensure we have minimal up-front constitution and spec directory available
mkdir -p "${TMP_WORKDIR}/specs" "${TMP_WORKDIR}/.specify"

pushd "${TMP_WORKDIR}" > /dev/null

# initialize only if missing, allow idempotent reruns -- no git init / no remote push
if [[ ! -d .specify ]]; then
  echo "[spec-kit-runner] initializing spec-kit project"
  spec-kit init . --ai generic --force || die "spec-kit init failed"
fi

echo "[spec-kit-runner] running spec-kit check"
spec-kit check . > spec-kit-check.log 2>&1 || {
  cat spec-kit-check.log
  die "spec-kit check failed"
}

# Post-run sanitization check: basic secret patterns
declare -a patterns=(
  'AKIA[0-9A-Z]{16}'
  'ASIA[0-9A-Z]{16}'
  'AIza[0-9A-Za-z_\-]{35}'
  'ya29\.[0-9A-Za-z_\-]+'
  '(?i)(secret|password|passwd|token|api[_-]?key)[[:space:]]*[:=][[:space:]]*[^[:space:]]+'
  '-----BEGIN RSA PRIVATE KEY-----'
  '-----BEGIN PRIVATE KEY-----'
)

leak_found=0
for p in "${patterns[@]}"; do
  matches="$(grep -RInE --binary-files=without-match --include='*' "$p" . 2>/dev/null || true)"
  if [[ -n "$matches" ]]; then
    leak_found=1
    echo "[spec-kit-runner][FATAL] secret pattern detected: $p"
    echo "$matches"
  fi
done

if [[ "$leak_found" -ne 0 ]]; then
  die "secret leak detected in generated artifacts"
fi

popd > /dev/null

archive_name="spec-kit-output-$(date -u +%Y%m%dT%H%M%SZ).tar.gz"
archive_path="${ARCHIVE_DIR}/${archive_name}"

echo "[spec-kit-runner] archiving output to ${archive_path}"
tar -C "${TMP_WORKDIR}" -czf "${archive_path}" .

# Retention: keep latest 10 archives.
mapfile -t cleanup_list < <(ls -1t "${ARCHIVE_DIR}"/spec-kit-output-*.tar.gz 2>/dev/null | tail -n +11)
for f in "${cleanup_list[@]:-}"; do
  echo "[spec-kit-runner] removing old archive: ${f}"
  rm -f -- "$f"
done

echo "[spec-kit-runner] done. archive retained: ${archive_path}"
