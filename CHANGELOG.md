# Changelog

Notable changes per release. Format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versions follow
[Semantic Versioning](https://semver.org/spec/v2.0.0.html), pre-1.0.

## [Unreleased]

### Added

- The QA slot is a lease. `qa_active` was cleared only by `ruver-qa`'s
  `verdict` node, so any other exit — `handed_off` on a context limit,
  `escalated`, a killed session — left the claim set for good. Every later
  `QA_REQUEST` then parked in `qa_waiting` and never ran, while the graph kept
  answering with a queue position. `qa_claimed_at` plus `qa_lease_minutes`
  makes an old claim free, and every terminal exit now releases.
- `qa_fix_loops` (default 2) bounds the `apply_qa` → `fix` → QA ring. fd bounds
  its own rings, but mode `fix` never re-enters the fd graph, so the most
  expensive loop in the system — a full QA plus a triage plus a fix — was the
  only unbounded one. `apply_qa` also escalates immediately when a finding id
  repeats across laps, which is the failure that actually happens.
- `qa_verdict_log` in the developer STATE: one row per QA lap. `qa_verdict` is a
  single overwritten field, so lap 6 used to leave a STATE identical to lap 1.
- STACK.md depth is capped at 3, and a push of a graph already on the stack is
  refused. `developer → qa → triage` is the deepest real chain; a fourth frame
  is a cycle.
- `tests/repo.sh` fails when a graph declares the same enum with different
  values in different files. It found four, each losing information: `scope`
  had `mono` in the schema and not in `ROUTING.md` or `HANDOFF.md`, `mcp_gate`
  was `passed | failed` in `HANDOFF.md` so a handoff could not express
  `passed_partial`, `ci.status` was missing `skipped_no_pr`, and the blocker
  rollup was called `status`, colliding with the graph's own.
- `$RUVER_ROOT/.ruver-bus/RUN_LOG.tsv`, a run ledger the graphs append to on
  every transition, and `ruver report` to read it: wall time and lap count per
  `graph/node`, plus the age of the QA claim. Observation only — nothing gates
  on it. See `skills/ruver-bus/LEDGER.md`.
- `version` in `.codex-plugin/marketplace.json` and
  `.cursor-plugin/marketplace.json`.

- `tests/repo.sh` gates the discovery block: the sum of every skill's name and
  description, which every host pastes into the system prompt on every turn.
  Codex caps that block at 8,000 characters and silently shortens or drops
  skills past it. The repo was at 8,934; it is now 7,587.
- `tests/repo.sh` holds reference files one directory below `SKILL.md`, so a
  partial read of a skill shows an agent everything it can load.
- `tests/repo.sh` reads the version out of `.codex-plugin/marketplace.json` and
  `.cursor-plugin/marketplace.json`, and checks the marketplace and plugin names
  across all four marketplaces. Those two files carried no version at all.
- `version` in `.codex-plugin/marketplace.json` and
  `.cursor-plugin/marketplace.json`.

### Changed

- Twenty-two skill descriptions are shorter. Process detail moved into the
  bodies; the trigger phrases stayed, because that is what routing reads.
- `skills/why/references/sources/*.md` are now `references/source-*.md`.
- 107 places across 47 skill files, 6 agent contracts and one command named
  Linear as *the* tracker. The field rename in 0.5.0 covered `linear_*` but not
  prose, so `DECISION_POLICY.md` alone pointed at it eleven times and an agent
  reading it would reach for Linear with `tracker: github_issues` in STATE.
  `tests/repo.sh` now fails on the bare name outside the files whose job is
  vendor mapping.

### Fixed

- Two Portuguese strings in English skill bodies: `route_confidence: alta |
  media | baixa` in `ROUTING.md` and `"fecha o spec?"` in `nodes/spec.md`.
- `docs/GRAPH_ENGINEER.md` step 2 still taught the pre-flatten link layout
  (`../../engines/<name>/...`). A contributor following it wrote links that
  leave the skills root.
- The README layout tree still showed `skills/graphs`, `skills/engines` and
  `skills/lib`, contradicting the paragraph under it.
- Prose across the docs and four skills still called the host contract
  `HOST.md`, a file that no longer exists. `tests/repo.sh` now fails on the name.
- `ruver-developer` described itself as delivering a *Linear* ticket, which the
  tracker genericization missed because the description is not a state field.
- `how` and `diagnose` carried `\"` inside a folded YAML scalar, so literal
  backslashes reached the skill picker.

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
