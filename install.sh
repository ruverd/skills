#!/usr/bin/env bash
# Install and update Ruver skills (flatten into agent homes).
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/ruverd/skills/main/install.sh | bash
#   ./install.sh setup
#   ruver update
#   ruver status
#   ruver uninstall
#
# Options: --dry-run  --yes / -y  --help
# Compat:  --uninstall  (same as uninstall)

set -euo pipefail

usage() {
  cat <<'EOF'
Install and update Ruver skills.

Usage:
  ruver                 Menu (TTY) or command list (no TTY)
  ruver setup           Flatten skills into agent homes
  ruver update          git pull --ff-only main, then setup
  ruver status          Repo, version, SHA, homes
  ruver uninstall       Remove our symlinks
  ruver uninstall --purge
                        Also delete the managed clone

Options:
  --dry-run     Print actions, write nothing
  --yes, -y     Skip confirmations
  -h, --help    Show this help

Examples:
  curl -fsSL https://raw.githubusercontent.com/ruverd/skills/main/install.sh | bash
  ruver setup
  ruver update
  ruver status
  ruver uninstall
EOF
}

CMD=""
DRY=0
YES=0
PURGE=0
UNINSTALL=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    setup|update|status|uninstall|menu|help)
      if [[ -n "$CMD" && "$CMD" != "$1" ]]; then
        echo "unknown arg: $1" >&2
        usage
        exit 1
      fi
      CMD="$1"
      shift
      ;;
    --dry-run) DRY=1; shift ;;
    --yes|-y) YES=1; shift ;;
    --purge) PURGE=1; shift ;;
    --uninstall) CMD="uninstall"; UNINSTALL=1; shift ;;
    --plugin|--grok-plugin)
      echo "Plugin install is not part of ruver." >&2
      echo "  grok plugin install ruver --trust" >&2
      echo "  claude plugins install ruver" >&2
      exit 1
      ;;
    -h|--help)
      if [[ -n "$CMD" && "$CMD" != "help" ]]; then
        usage
        exit 0
      fi
      usage
      exit 0
      ;;
    *)
      echo "unknown arg: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ "$CMD" == "help" ]]; then
  usage
  exit 0
fi

if [[ "$CMD" == "uninstall" ]]; then
  UNINSTALL=1
fi

resolve_file() {
  local target="$1"
  local dir dest
  while [[ -L "$target" ]]; do
    dir="$(cd "$(dirname "$target")" && pwd)"
    dest="$(readlink "$target")"
    case "$dest" in
      /*) target="$dest" ;;
      *) target="$dir/$dest" ;;
    esac
  done
  dir="$(cd "$(dirname "$target")" && pwd)"
  echo "$dir/$(basename "$target")"
}

SELF="$(resolve_file "${BASH_SOURCE[0]:-$0}")"
REPO="$(cd "$(dirname "$SELF")" && pwd)"
BACKUP_ROOT="${SKILLS_BACKUP_ROOT:-${AI_SKILLS_BACKUP_ROOT:-$HOME/.skills-backups}}"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/ruver"
CONFIG_FILE="$CONFIG_DIR/config"
DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
MANAGED_REPO="$DATA_HOME/ruver/repo"
DEFAULT_ORIGIN="https://github.com/ruverd/skills.git"
BIN_DIR="$HOME/.local/bin"
BIN_LINK="$BIN_DIR/ruver"

config_get() {
  local key="$1"
  [[ -f "$CONFIG_FILE" ]] || return 0
  sed -n "s/^${key}=//p" "$CONFIG_FILE" | head -1
}

config_set_repo() {
  run mkdir -p "$CONFIG_DIR"
  if [[ "$DRY" -eq 1 ]]; then
    echo "dry-run: write $CONFIG_FILE repo=$1"
    return 0
  fi
  printf 'repo=%s\norigin=%s\n' "$1" "${2:-$DEFAULT_ORIGIN}" >"$CONFIG_FILE"
}

plugin_version() {
  sed -n 's/.*"version": "\([^"]*\)".*/\1/p' "$REPO/plugin.json" | head -1
}

ensure_ruver_home() {
  if [[ -d "$HOME/.grok/ruver" && ! -e "$HOME/.ruver" ]]; then
    echo "link   $HOME/.ruver -> $HOME/.grok/ruver"
    run ln -sfn "$HOME/.grok/ruver" "$HOME/.ruver"
  else
    run mkdir -p "$HOME/.ruver"
  fi
}

ensure_bin() {
  run mkdir -p "$BIN_DIR"
  run ln -sfn "$SELF" "$BIN_LINK"
  echo "link   $BIN_LINK -> $SELF"
}

ensure_path_snippet() {
  local line='# ruver PATH'
  local block rc
  case ":$PATH:" in
    *":$BIN_DIR:"*) return 0 ;;
  esac
  block=$(printf '%s\nexport PATH="%s:$PATH"\n' "$line" "$BIN_DIR")
  for rc in "$HOME/.zshrc" "$HOME/.bashrc"; do
    if [[ -f "$rc" ]] && grep -q "$line" "$rc"; then
      continue
    fi
    if [[ "$DRY" -eq 1 ]]; then
      echo "dry-run: append PATH to $rc"
      continue
    fi
    mkdir -p "$(dirname "$rc")"
    touch "$rc"
    printf '\n%s\n' "$block" >>"$rc"
  done
}

cmd_setup() {
  if [[ ! -d "$REPO/skills" ]]; then
    echo "missing $REPO/skills" >&2
    exit 1
  fi
  echo "repo    $REPO"
  echo
  config_set_repo "$REPO"
  ensure_ruver_home
  install_skills \
    "$HOME/.agents/skills" \
    "$HOME/.grok/skills" \
    "$HOME/.claude/skills" \
    "$HOME/.cursor/skills" \
    "$HOME/.codex/skills"
  install_tree "$REPO/agents" \
    "$HOME/.grok/agents" \
    "$HOME/.claude/agents"
  install_tree "$REPO/commands" \
    "$HOME/.grok/commands" \
    "$HOME/.claude/commands"
  ensure_bin
  ensure_path_snippet
  echo
  echo "done. restart the agent session, then run /developer"
  echo "  export PATH=\"$BIN_DIR:\$PATH\""
}

cmd_update() {
  local repo
  repo="$(config_get repo)"
  repo="${repo:-$REPO}"
  if ! git -C "$repo" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "not a git clone: $repo" >&2
    echo "  ruver setup" >&2
    exit 1
  fi
  REPO="$repo"
  SELF="$repo/install.sh"
  if [[ -n "$(git -C "$repo" status --porcelain)" ]]; then
    echo "working tree is dirty. commit or stash, then ruver update" >&2
    git -C "$repo" status -sb >&2
    exit 1
  fi
  local old new oldv newv
  old="$(git -C "$repo" rev-parse --short HEAD)"
  oldv="$(plugin_version)"
  if [[ "$DRY" -eq 1 ]]; then
    echo "dry-run: git -C $repo fetch origin"
    echo "dry-run: git -C $repo pull --ff-only origin main"
    echo "version: $oldv $old -> (dry-run)"
    return 0
  fi
  git -C "$repo" fetch origin
  if ! git -C "$repo" pull --ff-only origin main; then
    echo "clone diverged from main. ruver status" >&2
    exit 1
  fi
  new="$(git -C "$repo" rev-parse --short HEAD)"
  newv="$(plugin_version)"
  echo "version: $oldv $old -> $newv $new"
  echo "sha: $old -> $new"
  cmd_setup
}

cmd_status() {
  local repo sha behind dest
  repo="$(config_get repo)"
  repo="${repo:-$REPO}"
  REPO="$repo"
  echo "repo     $repo"
  echo "version  $(plugin_version)"
  if git -C "$repo" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    sha="$(git -C "$repo" rev-parse --short HEAD)"
    echo "sha      $sha"
    git -C "$repo" fetch origin >/dev/null 2>&1 || true
    behind="$(git -C "$repo" rev-list --count HEAD..origin/main 2>/dev/null || echo "?")"
    echo "behind   $behind"
  fi
  if command -v ruver >/dev/null 2>&1; then
    echo "path     $(command -v ruver)"
  else
    echo "path     ruver not on PATH (export PATH=\"$BIN_DIR:\$PATH\")"
  fi
  for dest in \
    "$HOME/.agents/skills/unslop" \
    "$HOME/.grok/skills/unslop" \
    "$HOME/.claude/skills/unslop" \
    "$HOME/.cursor/skills/unslop" \
    "$HOME/.codex/skills/unslop"
  do
    if [[ -L "$dest" ]]; then
      if is_ours "$dest"; then
        echo "ok       $dest"
      else
        echo "not ours $dest"
      fi
    elif [[ -e "$dest" ]]; then
      echo "not ours $dest"
    else
      echo "missing  $dest"
    fi
  done
  if command -v grok >/dev/null 2>&1 && grok plugin list 2>/dev/null | grep -qi ruver; then
    echo "warn     grok plugin ruver is also installed (duplicate skills)"
  fi
  if command -v claude >/dev/null 2>&1 && claude plugins list 2>/dev/null | grep -qi ruver; then
    echo "warn     claude plugin ruver is also installed (duplicate skills)"
  fi
}

cmd_uninstall() {
  UNINSTALL=1
  install_skills \
    "$HOME/.agents/skills" \
    "$HOME/.grok/skills" \
    "$HOME/.claude/skills" \
    "$HOME/.cursor/skills" \
    "$HOME/.codex/skills"
  install_tree "$REPO/agents" \
    "$HOME/.grok/agents" \
    "$HOME/.claude/agents"
  install_tree "$REPO/commands" \
    "$HOME/.grok/commands" \
    "$HOME/.claude/commands"
  if [[ -L "$BIN_LINK" ]]; then
    local t
    t="$(readlink "$BIN_LINK")"
    if [[ "$t" == "$SELF" || "$t" == "$REPO/install.sh" ]]; then
      echo "rm     $BIN_LINK"
      run rm "$BIN_LINK"
    fi
  fi
  echo "unlinked this repo from local agent homes."
  if [[ "$PURGE" -ne 1 ]]; then
    return 0
  fi
  local repo
  repo="$(config_get repo)"
  if [[ "$repo" != "$MANAGED_REPO" ]]; then
    echo "this is your development clone: $repo" >&2
    echo "refusing --purge" >&2
    exit 1
  fi
  if [[ "$YES" -ne 1 && -t 0 ]]; then
    printf 'Delete %s ? [y/N] ' "$MANAGED_REPO"
    read -r ans
    case "$ans" in y|Y|yes) ;; *) echo "aborted."; return 0 ;; esac
  fi
  echo "rm     $MANAGED_REPO"
  run rm -rf "$MANAGED_REPO"
  echo "rm     $CONFIG_FILE"
  run rm -f "$CONFIG_FILE"
}

ts() { date +%Y%m%d%H%M%S; }

is_ours() {
  local dest="$1"
  [[ -L "$dest" ]] || return 1
  local target
  target="$(readlink "$dest")"
  [[ "$target" == "$REPO/"* ]]
}

run() {
  if [[ "$DRY" -eq 1 ]]; then
    echo "dry-run: $*"
    return 0
  fi
  "$@"
}

link_one() {
  local src="$1"
  local dest="$2"
  run mkdir -p "$(dirname "$dest")"
  if [[ -L "$dest" ]]; then
    local cur
    cur="$(readlink "$dest")"
    if [[ "$cur" == "$src" ]]; then
      echo "ok     $dest"
      return 0
    fi
    echo "relink $dest"
    run ln -sfn "$src" "$dest"
    return 0
  fi
  if [[ -e "$dest" ]]; then
    local bak_dir="$BACKUP_ROOT/$(ts)"
    local bak="$bak_dir/$(basename "$dest")"
    echo "backup $dest -> $bak"
    run mkdir -p "$bak_dir"
    run mv "$dest" "$bak"
  fi
  echo "link   $dest -> $src"
  run ln -sfn "$src" "$dest"
}

unlink_one() {
  local dest="$1"
  if is_ours "$dest"; then
    echo "rm     $dest"
    run rm "$dest"
  elif [[ -e "$dest" ]]; then
    echo "keep   $dest (not a symlink to this repo)"
  fi
}

# Flat kinds (agents, commands): dest gets the same basename.
install_tree() {
  local src_dir="$1"
  shift
  local dest_dirs=("$@")
  [[ -d "$src_dir" ]] || return 0
  local src dest dest_dir name
  for src in "$src_dir"/*; do
    [[ -e "$src" ]] || continue
    name="$(basename "$src")"
    for dest_dir in "${dest_dirs[@]}"; do
      dest="$dest_dir/$name"
      if [[ "$UNINSTALL" -eq 1 ]]; then
        unlink_one "$dest"
      else
        link_one "$src" "$dest"
      fi
    done
  done
}

# Nested skills/{graphs,engines,lib}/<name> → dest/<name>
install_skills() {
  local dest_dirs=("$@")
  local cat src_dir src dest dest_dir name
  for cat in graphs engines lib; do
    src_dir="$REPO/skills/$cat"
    [[ -d "$src_dir" ]] || continue
    for src in "$src_dir"/*; do
      [[ -d "$src" ]] || continue
      [[ -f "$src/SKILL.md" ]] || continue
      name="$(basename "$src")"
      for dest_dir in "${dest_dirs[@]}"; do
        dest="$dest_dir/$name"
        if [[ "$UNINSTALL" -eq 1 ]]; then
          unlink_one "$dest"
        else
          link_one "$src" "$dest"
        fi
      done
    done
  done
}

if [[ ! -d "$REPO/skills" && "$CMD" != "" && "$CMD" != "help" ]]; then
  echo "missing $REPO/skills" >&2
  exit 1
fi

case "${CMD:-setup}" in
  setup) cmd_setup ;;
  update) cmd_update ;;
  status) cmd_status ;;
  uninstall) cmd_uninstall ;;
  *) echo "not implemented: $CMD" >&2; exit 1 ;;
esac
