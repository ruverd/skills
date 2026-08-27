#!/usr/bin/env bash
# Install Ruver skills into the local agent homes.
#
# Default: flatten skills/{graphs,engines,branch,lib}/<name> into
#   ~/.agents  ~/.grok  ~/.claude  ~/.cursor  ~/.codex
# so /ruver-developer, /ruver-lstm, and /ruver-qa stay flat slash names.
#
# Usage:
#   ./install.sh
#   ./install.sh --dry-run
#   ./install.sh --plugin          # also register this repo as a Grok marketplace
#   ./install.sh --uninstall

set -euo pipefail

REPO="$(cd "$(dirname "$0")" && pwd)"
BACKUP_ROOT="${SKILLS_BACKUP_ROOT:-${AI_SKILLS_BACKUP_ROOT:-$HOME/.skills-backups}}"
DRY=0
GROK_PLUGIN=0
UNINSTALL=0

usage() {
  sed -n '2,16p' "$0" | sed 's/^# \?//'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY=1; shift ;;
    --plugin|--grok-plugin) GROK_PLUGIN=1; shift ;;
    --uninstall) UNINSTALL=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown arg: $1" >&2; usage; exit 1 ;;
  esac
done

if [[ ! -d "$REPO/skills" ]]; then
  echo "missing $REPO/skills" >&2
  exit 1
fi

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

# Nested skills/{graphs,engines,branch,lib}/<name> → dest/<name>
install_skills() {
  local dest_dirs=("$@")
  local cat src_dir src dest dest_dir name
  for cat in graphs engines branch lib; do
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

echo "repo    $REPO"
echo

# Harness-neutral disk. Keep existing ~/.grok/ruver jobs alive.
if [[ "$UNINSTALL" -eq 0 ]]; then
  if [[ -d "$HOME/.grok/ruver" && ! -e "$HOME/.ruver" ]]; then
    echo "link   $HOME/.ruver -> $HOME/.grok/ruver"
    run ln -sfn "$HOME/.grok/ruver" "$HOME/.ruver"
  else
    run mkdir -p "$HOME/.ruver"
  fi
fi

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

if [[ "$GROK_PLUGIN" -eq 1 ]]; then
  if ! command -v grok >/dev/null 2>&1; then
    echo "grok CLI not on PATH; skip --plugin" >&2
  elif [[ "$UNINSTALL" -eq 1 ]]; then
    echo "plugin uninstall is: grok plugin uninstall ruver --confirm"
  else
    if grok plugin marketplace list 2>/dev/null | grep -qE 'ruverd/skills|ruverd/ai-skills|\bskills\b'; then
      echo "ok     grok marketplace already lists this repo"
    else
      echo "add    grok plugin marketplace add $REPO"
      run grok plugin marketplace add "$REPO"
    fi
    echo "install grok plugin install ruver --trust"
    run grok plugin install ruver --trust
  fi
fi

echo
if [[ "$UNINSTALL" -eq 1 ]]; then
  echo "unlinked this repo from local agent homes."
else
  echo "done. restart the agent session, then run:"
  echo "  /ruver-developer"
  echo "  /ruver-lstm"
  echo "  /ruver-qa"
fi
