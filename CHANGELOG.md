# Changelog

Notable changes per release. Format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versions follow
[Semantic Versioning](https://semver.org/spec/v2.0.0.html), pre-1.0.

## [Unreleased]

### Added

- `ruver --version` / `-V`.
- `--only <hosts>` and `--all` to choose which agent homes `setup` writes to.
- `--no-path` to leave `~/.zshrc` and `~/.bashrc` alone.
- A symlink capability check. `setup` refuses on a filesystem where `ln -s`
  silently copies, because `ruver update` would then never propagate.
- `tests/repo.sh`: link, frontmatter, manifest and structure gates.
- `shellcheck` in CI.
- `category: graph | engine | lib` in every `SKILL.md`.
- `commands/goal.md`, so `/goal` exists next to `/developer`, `/qa`,
  `/reviewer`, `/lstm` and `/memory`.
- `CONTRIBUTING.md`, `SECURITY.md`, `CODEOWNERS`, issue and PR templates.

### Changed

- `setup` links only into agent homes that already exist. It used to create
  `~/.codex/skills` and `~/.cursor/skills` on machines without those tools.
- `setup` names each shell rc file before appending to it.
- The Grok plugin index is derived from frontmatter instead of hand-maintained.
- All four manifests are checked to agree on the version.
- README no longer promises Windows Git Bash support. WSL is the supported path.

### Fixed

- `.claude-plugin/plugin.json` omitted `ruver-memory`, so `/memory` did not
  exist for Claude Code plugin users.
- Version drift: two manifests said 0.4.2 while two said 0.4.3.
- `architect` referenced an `arena` skill that is not bundled here.
- Four `shellcheck` findings in `install.sh` and `tests/`.

### Removed

- The seven `commands/ruver_*.md` underscore aliases. They doubled the command
  picker on every host and were never documented. The role names `ruver_*`
  remain in `agents/`.
- `docs/superpowers/`: internal working notes that shipped to every user.
