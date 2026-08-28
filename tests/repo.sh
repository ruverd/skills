#!/usr/bin/env bash
# Repo invariants. Structure, links, frontmatter, manifests.
# Dev-only: needs python3. End users installing skills need just git and curl.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LIB="$ROOT/tests/lib"
FAILED=0

ok() { echo "ok  $*"; }
bad() { echo "FAIL: $*" >&2; FAILED=1; }

check() {
  local name="$1"
  shift
  local out
  if out="$("$@" 2>&1)"; then
    ok "$name"
  else
    bad "$name"
    [[ -n "$out" ]] && echo "$out" | sed 's/^/      /' >&2
  fi
}

need_python() {
  command -v python3 >/dev/null 2>&1 && return 0
  echo "FAIL: python3 is required to run tests/repo.sh" >&2
  exit 1
}

need_python

check links python3 "$LIB/check_links.py" "$ROOT"

if [[ "$FAILED" -ne 0 ]]; then
  echo "repo checks failed" >&2
  exit 1
fi
echo "all passed"
