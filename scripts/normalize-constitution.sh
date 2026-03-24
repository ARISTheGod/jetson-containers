#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

AI_PATH="AI_CONSTITUTION.md"
CANON_PATH="CONSTITUTION.md"

if [[ -f "$CANON_PATH" ]]; then
  echo "[normalize-constitution] canonical $CANON_PATH exists."
  if [[ -f "$AI_PATH" && ! -f "$CANON_PATH" ]]; then
    # unreachable because we checked existence above
    cp "$AI_PATH" "$CANON_PATH"
  fi
  exit 0
fi

if [[ -f "$AI_PATH" ]]; then
  echo "[normalize-constitution] creating canonical $CANON_PATH from $AI_PATH"
  cp "$AI_PATH" "$CANON_PATH"
  exit 0
fi

cat > "$CANON_PATH" <<'EOF'
# Constitution for jetson-containers

Add AI + engineering governance here. This file is required for AI agents and human review.
EOF

echo "[normalize-constitution] created placeholder $CANON_PATH"
