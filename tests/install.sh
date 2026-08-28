#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
INSTALL="$ROOT/install.sh"

fail() { echo "FAIL: $*" >&2; exit 1; }
ok() { echo "ok  $*"; }

assert_eq() {
  local got="$1" want="$2" msg="$3"
  [[ "$got" == "$want" ]] || fail "$msg (got '$got' want '$want')"
}

assert_file() { [[ -e "$1" ]] || fail "missing $1"; }
assert_link() { [[ -L "$1" ]] || fail "not a symlink: $1"; }
assert_not() { [[ ! -e "$1" ]] || fail "should not exist: $1"; }

run_install() {
  HOME="$TEST_HOME" XDG_CONFIG_HOME="$TEST_HOME/.config" \
    XDG_DATA_HOME="$TEST_HOME/.local/share" \
    "$INSTALL" "$@"
}

# --- help ---
out="$(HOME=/tmp "$INSTALL" --help)"
echo "$out" | grep -q 'Examples:' || fail "help missing Examples:"
echo "$out" | grep -q 'ruver setup' || fail "help missing ruver setup"
echo "$out" | grep -q 'curl -fsSL' || fail "help missing curl one-liner"
ok help

set +e
HOME=/tmp "$INSTALL" not-a-command >/dev/null 2>&1
got=$?
set -e
assert_eq "$got" "1" "unknown command exit"
ok unknown-command

TEST_HOME="$(mktemp -d "${TMPDIR:-/tmp}/ruver-cli.XXXXXX")"
trap 'rm -rf "$TEST_HOME"' EXIT

run_install setup >/tmp/ruver-setup.out
assert_file "$TEST_HOME/.config/ruver/config"
grep -q "^repo=" "$TEST_HOME/.config/ruver/config" || fail "config missing repo="
assert_link "$TEST_HOME/.agents/skills/unslop"
assert_link "$TEST_HOME/.local/bin/ruver"
readlink "$TEST_HOME/.local/bin/ruver" | grep -q 'install.sh' || fail "bin not install.sh"
assert_file "$TEST_HOME/.ruver"
assert_not "$TEST_HOME/.ruver/memory.md"
ok setup

# PATH snippet once
grep -q '# ruver PATH' "$TEST_HOME/.zshrc" || fail "missing zshrc PATH block"
run_install setup >/dev/null
count="$(grep -c '# ruver PATH' "$TEST_HOME/.zshrc" || true)"
assert_eq "$count" "1" "PATH block duplicated"
ok setup-path-once

echo "all passed"
