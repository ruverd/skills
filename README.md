# ai-skills

Ruver graphs for coding agents. Same files on **Grok**, **Claude Code**,
**Codex**, and **Cursor**.

```text
/ruver-developer DEV-1234
/ruver-lstm https://github.com/org/repo/pull/99
/ruver-qa https://github.com/org/repo/pull/99
```

This repo is the source of truth for the graphs I actually run. It is
not a dump of every third-party skill on the machine.

## Graph engineer

The main thread of those commands is a **graph engineer**, not an
implementer.

It walks a GRAPH (nodes + edges). It writes STATE under `~/.ruver`.
It spawns a **worker** when a node must touch product code. It never
opens `src/` itself.

Three layers, kept apart:

| Layer | Lives in | Example |
|---|---|---|
| Graph | `plugins/ruver/skills/*/GRAPH.md` | admit → deliver → mergeable → QA |
| Host | [`plugins/ruver/HOST.md`](plugins/ruver/HOST.md) | how *this* harness spawns a child or wakes later |
| Product | the target repo `AGENTS.md` | test command, reviewers, Linear team |

A graph that says `spawn_subagent`, `model: grok-4.6`, or a company's
GitHub handles has leaked. Host APIs stay in HOST.md. Product policy
stays in the repo you are in.

Full write-up: [docs/GRAPH_ENGINEER.md](docs/GRAPH_ENGINEER.md).
Architecture: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## Install

```bash
git clone https://github.com/ruverd/ai-skills.git ~/Developer/ai-skills
~/Developer/ai-skills/install.sh
```

That links skills into every harness home:

| Path | Host |
|---|---|
| `~/.agents/skills` | shared (Grok, Codex, others that scan `.agents`) |
| `~/.grok/skills` `~/.grok/agents` `~/.grok/commands` | Grok |
| `~/.claude/skills` `~/.claude/agents` `~/.claude/commands` | Claude Code |
| `~/.cursor/skills` | Cursor |
| `~/.codex/skills` | Codex |

Runtime disk is **`~/.ruver/<slug>/`**, shared across hosts. If you
already had `~/.grok/ruver`, install.sh symlinks `~/.ruver` to it so
live jobs keep running.

```bash
./install.sh --dry-run
./install.sh --plugin          # also register the Grok marketplace
./install.sh --uninstall
```

### Plugin marketplaces

```bash
# Grok
grok plugin marketplace add ruverd/ai-skills
grok plugin install ruver --trust

# Claude Code / Cursor / Codex
# add ruverd/ai-skills as a marketplace, install plugin `ruver`
```

Manifests: `.grok-plugin/`, `.claude-plugin/`, `.cursor-plugin/`,
`.codex-plugin/`.

Restart the session after install.

## The three commands

### `/ruver-developer`

Deliver a Linear ticket or a free-text goal.

1. Grill the design against the repo.
2. Write a spec and tickets.
3. Implement with TDD in a **worker** (`ruver-fd-coder`). The
   graph engineer does not touch product code.
4. Open a **draft** PR.
5. Wait until CI is green **and** the PR is MERGEABLE.
6. Hand off to `/ruver-qa` over the bus.

Never merges. `gh pr ready` only after QA PASS.

```text
/ruver-developer DEV-1212
/ruver-developer the notification inbox on the dashboard
/ruver-developer resume
```

Skill: [`plugins/ruver/skills/ruver-developer`](plugins/ruver/skills/ruver-developer).
Engine: [`ruver-feature-delivery`](plugins/ruver/skills/ruver-feature-delivery).

### `/ruver-lstm`

Looks shit to me. Author side of a review.

1. Ingest a PR, review, or comment URL.
2. Rebase if the branch is dirty or conflicting.
3. Verify each comment (`receiving-code-review`).
4. Patch should-fix on the **same branch** with TDD.
5. Reply, resolve threads, re-request review.

Never opens a new PR. Draft stays draft.

```text
/ruver-lstm https://github.com/org/repo/pull/99
/ruver-lstm resume
```

Skill: [`plugins/ruver/skills/ruver-lstm`](plugins/ruver/skills/ruver-lstm).

### `/ruver-qa`

QA a GitHub PR the way a user would.

1. Claim the single QA slot (extras queue).
2. Write a plan from the **diff** before clicking anything.
3. Exercise the screens in a browser. Record video.
4. Product suspicion → `/ruver-triage` over the bus.
5. Post a PR comment with the verdict and the video.

A backend-only PR still has to hit the frontend route that calls it.
Unit tests are not a complete run.

```text
/ruver-qa https://github.com/org/repo/pull/99
```

Skill: [`plugins/ruver/skills/ruver-qa`](plugins/ruver/skills/ruver-qa).

## How the graphs fit

```
          /ruver-developer
                 │
                 ▼
        ruver-feature-delivery
                 │
           draft PR, CI green
                 │
                 ▼
             /ruver-qa  ──►  /ruver-triage
                 │                │
            QA_RESULT        PR_BUG ──► developer (fix)
                 │
            PASS → ready

/ruver-reviewer ──► /ruver-code-review ──► GitHub review
/ruver-lstm     ──► patch the same PR
```

They talk through **ruver-bus** files, not nested graph agents.

Runtime state:

```text
~/.ruver/<slug>/.ruver-developer/
~/.ruver/<slug>/.ruver-qa/
~/.ruver/<slug>/.ruver-bus/
```

`<slug>` is the git toplevel with `/` replaced by `-`. Details:
[`ruver-bus/DISK.md`](plugins/ruver/skills/ruver-bus/DISK.md).

## Catalog

### Skills

Each folder is a slash command of the same name.

| Skill | What it does |
|---|---|
| `ruver-developer` | Orchestrate delivery + MERGEABLE + QA handoff. |
| `ruver-lstm` | Consume review comments and patch the same branch. |
| `ruver-qa` | Plan from the diff, browser QA, comment with video. |
| `ruver-feature-delivery` | Grill → spec → tickets → TDD implement → review → CI. |
| `ruver-bus` | Envelopes, job slot, stack between graphs. |
| `ruver-reviewer` | Run code-review, classify CI, optionally bus a result. |
| `ruver-code-review` | Adaptive PR review via `gh`. One artifact per PR. |
| `ruver-triage` | Classify a QA finding: PR_BUG / EXISTING / NEW / NOT_A_BUG / BLOCKED. |
| `ruver-goal` | `schedule_wake` until QA commented with video. |
| `ruver-validate-branch` | Pre-PR local validation (typecheck, lint, tests, then PR). |
| `ruver-create-pr-frontend` | Draft an empath-ui PR description. |
| `ruver-create-pr-backend` | Draft an empath-api-v2 PR description. |

Underscore aliases (`/ruver_developer`, `/ruver_lstm`, `/ruver_qa`,
`/ruver-fd`) live in `plugins/ruver/commands/` and point at the same
skills.

### Agents

Spawned as workers. Graph names (`ruver_developer`, `ruver_qa`, …)
are **roles for the main thread**. Do not spawn those. Spawn the
`ruver-fd-*` workers (or general-purpose with the node file pasted).

| Agent | Job |
|---|---|
| `ruver_developer` | Main-thread developer graph. |
| `ruver_qa` | Main-thread QA graph. |
| `ruver_reviewer` | Main-thread reviewer graph. |
| `ruver_triage` | Main-thread triage graph. |
| `ruver-fd-coder` | Implement one ticket, TDD red → green. |
| `ruver-fd-tester` | Hard gate: real typecheck/lint/test exit codes. |
| `ruver-fd-reviewer` | Read-only review of the fd design. |
| `ruver-fd-quality` | Quality pass before the PR. |
| `ruver-fd-shipper` | Commit, push, draft PR. Never merge. |
| `ruver-fd-debugger` | Root cause before a fix. One TDD repro ticket. |
| `ruver-fd-triage` | Route full_feature vs debug_fix vs light_change. |
| `ruver-fd-context` | Verify MCP / external context before implement. |
| `ruver-fd-ci` | Watch `gh pr checks` after the PR exists. |
| `ruver-fd-fullstack` | FE+BE worktrees, same branch name. |
| `ruver-fd-blocker` | Dependency blocker (missing contract, open ticket). |
| `ruver-fd-planner` | Legacy name. Spec/tickets stay on the main thread. |
| `ruver-fd-brainstormer` | Legacy name. Grill stays on the main thread. |

### Layout

```text
ai-skills/
  README.md
  install.sh
  docs/GRAPH_ENGINEER.md
  docs/ARCHITECTURE.md
  plugins/ruver/
    HOST.md                   # harness primitives
    skills/<name>/SKILL.md
    agents/*.md
    commands/*.md
```

Skills are siblings. Cross-links use `../ruver-bus/...`.

## What this repo does not include

- Third-party skills (pstack, caveman, Cursor team kit, cmux, …).
- Runtime `.ruver-*` state. That stays in `~/.ruver/`.

LSTM expects `receiving-code-review` and `unslop` if those skills are
installed. QA expects `gh`, a browser, and Playwright on the target app.

`ruver-create-pr-*` are empath-specific extras. The core graphs are not.

## Add or edit a skill

Follow [docs/GRAPH_ENGINEER.md](docs/GRAPH_ENGINEER.md). Short version:

1. Sibling under `plugins/ruver/skills/<name>/`.
2. Relative links only. No `~/.claude`, `~/.grok`, `~/.codex`.
3. Host primitives → HOST.md. Product policy → the target repo.
4. `./install.sh` then commit.

```bash
grok plugin validate plugins/ruver
```

## License

MIT. See [LICENSE](LICENSE).
