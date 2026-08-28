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
GROK_PLUGIN=0

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

REPO="$(cd "$(dirname "$0")" && pwd)"
BACKUP_ROOT="${SKILLS_BACKUP_ROOT:-${AI_SKILLS_BACKUP_ROOT:-$HOME/.skills-backups}}"

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
    if grok plugin marketplace list 2>/dev/null | grep -qE 'ruverd/skills|\bskills\b'; then
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
