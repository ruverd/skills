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
printf '%s\n' '{"name": "ruver", "version": "0.0.1"}' >"$mini/plugin.json"
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

ahead="$(mktemp -d "${TMPDIR:-/tmp}/ruver-ahead.XXXXXX")"
trap 'rm -rf "$TEST_HOME" "$SKIP_HOME" "$mini" "${mini}.git" "$MINI_HOME" "$ahead"' EXIT
git clone -q "${mini}.git" "$ahead"
git -C "$ahead" -c user.email=t@t -c user.name=t commit --allow-empty -qm second
git -C "$ahead" push -q origin main

set +e
HOME="$MINI_HOME" XDG_CONFIG_HOME="$MINI_HOME/.config" \
  XDG_DATA_HOME="$MINI_HOME/.local/share" \
  "$mini/install.sh" update >/tmp/ruver-ff.out 2>/tmp/ruver-ff.err
got=$?
set -e
[[ "$got" -eq 0 ]] || fail "clean update exit $got $(cat /tmp/ruver-ff.err)"
grep -q 'version:' /tmp/ruver-ff.out || fail "update missing version:"
ver="$(grep '^version:' /tmp/ruver-ff.out | head -1)"
old_sha="$(grep -oE '[0-9a-f]{7,}' <<< "$ver" | head -1)"
new_sha="$(grep -oE '[0-9a-f]{7,}' <<< "$ver" | tail -1)"
[[ -n "$old_sha" && -n "$new_sha" && "$old_sha" != "$new_sha" ]] \
  || fail "update did not advance SHA ($ver)"
ok update-clean

# Linked worktree: .git is a file, so [[ -d repo/.git ]] is the wrong check.
mini_wt="${mini}-wt"
git -C "$mini" worktree add "$mini_wt" -b wt-test >/dev/null
[[ -f "$mini_wt/.git" ]] || fail "worktree .git should be a file"
[[ ! -d "$mini_wt/.git" ]] || fail "worktree .git should not be a directory"
WT_HOME="$(mktemp -d "${TMPDIR:-/tmp}/ruver-wt-home.XXXXXX")"
trap 'rm -rf "$TEST_HOME" "$SKIP_HOME" "$mini" "${mini}.git" "$MINI_HOME" "$ahead" "$mini_wt" "$WT_HOME"' EXIT

HOME="$WT_HOME" XDG_CONFIG_HOME="$WT_HOME/.config" \
  XDG_DATA_HOME="$WT_HOME/.local/share" \
  "$mini_wt/install.sh" setup >/dev/null

set +e
HOME="$WT_HOME" XDG_CONFIG_HOME="$WT_HOME/.config" \
  XDG_DATA_HOME="$WT_HOME/.local/share" \
  "$mini_wt/install.sh" update >/tmp/ruver-wt.out 2>/tmp/ruver-wt.err
got=$?
set -e
[[ "$got" -eq 0 ]] || fail "worktree update exit $got $(cat /tmp/ruver-wt.err)"
if grep -qi 'not a git clone' /tmp/ruver-wt.err /tmp/ruver-wt.out; then
  fail "worktree treated as not a git clone"
fi
ok update-worktree

mkdir -p "$TEST_HOME/.ruver"
echo '# Memory' >"$TEST_HOME/.ruver/memory.md"
mkdir -p "$TEST_HOME/.agents/skills"
echo mine >"$TEST_HOME/.agents/skills/foreign-file"
run_install uninstall >/tmp/ruver-un.out
assert_not "$TEST_HOME/.agents/skills/unslop"
assert_file "$TEST_HOME/.ruver/memory.md"
assert_file "$TEST_HOME/.agents/skills/foreign-file"
ok uninstall-keeps-memory

set +e
HOME="$TEST_HOME" XDG_CONFIG_HOME="$TEST_HOME/.config" \
  XDG_DATA_HOME="$TEST_HOME/.local/share" \
  "$INSTALL" uninstall --purge --yes >/tmp/ruver-purge.out 2>/tmp/ruver-purge.err
got=$?
set -e
assert_eq "$got" "1" "purge of checkout clone must fail"
assert_file "$TEST_HOME/.ruver/memory.md"
ok purge-refuses-checkout

man="$TEST_HOME/.local/share/ruver/repo"
mkdir -p "$man"
git -C "$man" init -q
printf 'repo=%s\norigin=%s\n' "$man" "https://github.com/ruverd/skills.git" \
  >"$TEST_HOME/.config/ruver/config"
HOME="$TEST_HOME" XDG_CONFIG_HOME="$TEST_HOME/.config" \
  XDG_DATA_HOME="$TEST_HOME/.local/share" \
  "$INSTALL" uninstall --purge --yes
assert_not "$man"
assert_file "$TEST_HOME/.ruver/memory.md"
ok purge-managed

# After purge, TEST_HOME may have uninstalled links and config pointing at a
# managed clone that was deleted. Restore setup first.
run_install setup >/dev/null
out="$(run_install status)"
echo "$out" | grep -q 'repo' || fail "status missing repo"
echo "$out" | grep -q 'version' || fail "status missing version"
echo "$out" | grep -q 'ok' || fail "status missing ok homes"
ok status

set +e
HOME="$TEST_HOME" "$INSTALL" --plugin >/tmp/ruver-plugin.out 2>/tmp/ruver-plugin.err
got=$?
set -e
assert_eq "$got" "1" "--plugin exit"
grep -q 'grok plugin install ruver' /tmp/ruver-plugin.err || fail "--plugin message"
ok plugin-refused

echo "all passed"
