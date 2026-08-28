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
grep -qx "repo=$ROOT" "$TEST_HOME/.config/ruver/config" || fail "repo= should be $ROOT"
assert_link "$TEST_HOME/.agents/skills/unslop"
assert_link "$TEST_HOME/.local/bin/ruver"
readlink "$TEST_HOME/.local/bin/ruver" | grep -q 'install.sh' || fail "bin not install.sh"
assert_file "$TEST_HOME/.ruver"
assert_not "$TEST_HOME/.ruver/memory.md"
ok setup

# PATH snippet once. TEST_HOME/.local/bin is not on PATH, so setup must write the block.
case ":$PATH:" in
  *":$TEST_HOME/.local/bin:"*) fail "test assumption: $TEST_HOME/.local/bin must not be on PATH" ;;
esac
grep -q '# ruver PATH' "$TEST_HOME/.zshrc" || fail "missing zshrc PATH block"
run_install setup >/dev/null
count="$(grep -c '# ruver PATH' "$TEST_HOME/.zshrc" || true)"
assert_eq "$count" "1" "PATH block duplicated"
ok setup-path-once

# PATH snippet skipped when BIN_DIR is already on PATH
SKIP_HOME="$(mktemp -d "${TMPDIR:-/tmp}/ruver-cli.XXXXXX")"
trap 'rm -rf "$TEST_HOME" "$SKIP_HOME"' EXIT
PATH="$SKIP_HOME/.local/bin:$PATH" \
  HOME="$SKIP_HOME" XDG_CONFIG_HOME="$SKIP_HOME/.config" \
  XDG_DATA_HOME="$SKIP_HOME/.local/share" \
  "$INSTALL" setup >/dev/null
if [[ -f "$SKIP_HOME/.zshrc" ]] && grep -q '# ruver PATH' "$SKIP_HOME/.zshrc"; then
  fail "PATH block should not be written when BIN_DIR is already on PATH"
fi
ok setup-path-skip-when-present

DRY_HOME="$(mktemp -d "${TMPDIR:-/tmp}/ruver-dry.XXXXXX")"
set +e
out="$(HOME="$DRY_HOME" XDG_CONFIG_HOME="$DRY_HOME/.config" \
  XDG_DATA_HOME="$DRY_HOME/.local/share" \
  "$INSTALL" setup --dry-run 2>&1)"
got=$?
set -e
[[ "$got" -eq 0 ]] || fail "dry-run setup exit $got"
grep -q 'dry-run:' <<< "$out" || fail "dry-run silent"
assert_not "$DRY_HOME/.config/ruver/config"
assert_not "$DRY_HOME/.agents/skills/unslop"
assert_not "$DRY_HOME/.local/bin/ruver"
rm -rf "$DRY_HOME"
ok dry-run-setup

run_install setup >/tmp/ruver-setup2.out
grep -q '^ok ' /tmp/ruver-setup2.out || fail "second setup has no ok lines"
assert_link "$TEST_HOME/.agents/skills/unslop"
ok setup-idempotent

# --- update: dirty abort, then clean fast-forward ---
mini="$(mktemp -d "${TMPDIR:-/tmp}/ruver-mini.XXXXXX")"
mkdir -p "$mini/skills/lib/unslop" "$mini/agents" "$mini/commands"
printf '%s\n' '{"name":"ruver","version":"0.0.1"}' >"$mini/plugin.json"
echo '# unslop' >"$mini/skills/lib/unslop/SKILL.md"
cp "$INSTALL" "$mini/install.sh"
chmod +x "$mini/install.sh"
git -C "$mini" init -q
git -C "$mini" add .
git -C "$mini" -c user.email=t@t -c user.name=t commit -qm init
git -C "$mini" branch -M main
git -C "$mini" clone --bare "$mini" "${mini}.git"
git -C "$mini" remote add origin "${mini}.git"
git -C "$mini" fetch origin
git -C "$mini" branch --set-upstream-to=origin/main main 2>/dev/null || true

MINI_HOME="$(mktemp -d "${TMPDIR:-/tmp}/ruver-mini-home.XXXXXX")"
trap 'rm -rf "$TEST_HOME" "$SKIP_HOME" "$mini" "${mini}.git" "$MINI_HOME"' EXIT
HOME="$MINI_HOME" XDG_CONFIG_HOME="$MINI_HOME/.config" \
  XDG_DATA_HOME="$MINI_HOME/.local/share" \
  "$mini/install.sh" setup >/dev/null

echo dirty >>"$mini/skills/lib/unslop/SKILL.md"
set +e
HOME="$MINI_HOME" XDG_CONFIG_HOME="$MINI_HOME/.config" \
  XDG_DATA_HOME="$MINI_HOME/.local/share" \
  "$mini/install.sh" update >/tmp/ruver-dirty.out 2>/tmp/ruver-dirty.err
got=$?
set -e
assert_eq "$got" "1" "dirty update should fail"
grep -qi 'stash\|commit' /tmp/ruver-dirty.err /tmp/ruver-dirty.out \
  || fail "dirty update message"
ok update-dirty

git -C "$mini" checkout -q -- skills/lib/unslop/SKILL.md
git -C "$mini" -c user.email=t@t -c user.name=t commit --allow-empty -qm second
git -C "$mini" push -q origin main

set +e
HOME="$MINI_HOME" XDG_CONFIG_HOME="$MINI_HOME/.config" \
  XDG_DATA_HOME="$MINI_HOME/.local/share" \
  "$mini/install.sh" update >/tmp/ruver-ff.out 2>/tmp/ruver-ff.err
got=$?
set -e
[[ "$got" -eq 0 ]] || fail "clean update exit $got $(cat /tmp/ruver-ff.err)"
grep -q 'version:' /tmp/ruver-ff.out || fail "update missing version:"
ok update-clean

echo "all passed"
