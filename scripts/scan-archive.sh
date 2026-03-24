#!/usr/bin/env bash
set -euo pipefail

# Offline secret scan for specs-archive
ARCHIVE_DIR=${1:-specs-archive}
TMPDIR=$(mktemp -d)
EXIT_CODE=0

if [ ! -d "$ARCHIVE_DIR" ]; then
  echo "Archive directory '$ARCHIVE_DIR' does not exist" >&2
  exit 2
fi

echo "Scanning archives under: $ARCHIVE_DIR"

for archive in "$ARCHIVE_DIR"/*.tar.gz; do
  [ -e "$archive" ] || continue
  base=$(basename "$archive")
  outdir="$TMPDIR/${base%.tar.gz}"
  mkdir -p "$outdir"
  tar -xzf "$archive" -C "$outdir" || { echo "Failed to extract $archive" >&2; continue; }

  report="$ARCHIVE_DIR/${base}.scan.txt"
  echo "Scan report for $base" > "$report"

  # Quick heuristic scans
  echo "Searching for private key markers..." >> "$report"
  grep -R --line-number -E "BEGIN (RSA|DSA|EC|OPENSSH|PRIVATE) KEY" "$outdir" >> "$report" 2>/dev/null || true

  echo "Searching for common API key patterns..." >> "$report"
  grep -R --line-number -E "(AKIA|AIza[0-9A-Za-z_-]{35}|xox[baprs]-|ghp_[A-Za-z0-9_]{36}|api[_-]?key|secret[_-]?key)" "$outdir" >> "$report" 2>/dev/null || true

  findings=$(wc -c < "$report" || true)
  if [ "$findings" -gt 50 ]; then
    echo "Potential secrets found in $base — see $report" >&2
    EXIT_CODE=3
  else
    echo "No obvious secrets found in $base" >> "$report"
  fi
done

rm -rf "$TMPDIR"
exit $EXIT_CODE
