# Changelog

Notable changes per release. Format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versions follow
[Semantic Versioning](https://semver.org/spec/v2.0.0.html), pre-1.0.

## [0.5.0] - 2026-08-28

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
- `skills/ruver-host`: the host contract, previously `HOST.md` at the repo root.
- `ruver-goal` gained `GRAPH.md`, `STATE.schema.md` and four nodes.
- `ruver-code-review` gained the `STATE.schema.md` it never had.

### Changed

- `setup` links only into agent homes that already exist. It used to create
  `~/.codex/skills` and `~/.cursor/skills` on machines without those tools.
- `setup` names each shell rc file before appending to it.
- The Grok plugin index is derived from frontmatter instead of hand-maintained.
- All four manifests are checked to agree on the version.
- README no longer promises Windows Git Bash support. WSL is the supported path.
- **Breaking:** one flat directory per skill. `skills/{graphs,engines,lib}/<name>`
  is now `skills/<name>`, and `category` in the frontmatter carries what the
  directory used to. No link may leave the skills root, which is what makes
  `../other-skill/FILE.md` resolve the same in git and after install.
- `ruver-code-review/SKILL.md` split from 668 lines into eight nodes and three
  references.
- `ruver-bus` is `category: lib`. It has no nodes and walks no edges, so it is
  documented as the shared protocol rather than as a graph.
- State fields are vendor-neutral: `linear_id` and friends are `tracker_id` and
  friends, selected by `tracker:`. Linear works exactly as before through
  `LINEAR.md`, now explicitly the Linear adapter.
- Optional MCP tools are named as capabilities and mapped in `ruver-host`.

### Fixed

- `.claude-plugin/plugin.json` omitted `ruver-memory`, so `/memory` did not
  exist for Claude Code plugin users.
- Version drift: two manifests said 0.4.2 while two said 0.4.3.
- `architect` referenced an `arena` skill that is not bundled here.
- Four `shellcheck` findings in `install.sh` and `tests/`.
- Links that reached outside their own skill resolved only on hosts that walk
  symlinks with the kernel. On a host that normalises the path string first,
  every graph silently lost its host contract.
- `setup` left dead symlinks behind when a skill or command was renamed or
  deleted, and the host kept offering them in the picker.

### Removed

- The seven `commands/ruver_*.md` underscore aliases. They doubled the command
  picker on every host and were never documented. The role names `ruver_*`
  remain in `agents/`.
- `docs/superpowers/`: internal working notes that shipped to every user.

## [0.4.3] and earlier

Not tracked in this file.

[0.5.0]: https://github.com/ruverd/skills/releases/tag/v0.5.0
