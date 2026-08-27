# ai-skills

Ruver graphs for coding agents. Same files on **Grok**, **Claude Code**,
**Codex**, and **Cursor**.

```text
/ruver-developer DEV-1234
/ruver-reviewer https://github.com/org/repo/pull/99
/ruver-lstm https://github.com/org/repo/pull/99
/ruver-qa https://github.com/org/repo/pull/99
```

Full list and deep pages: [docs/commands](docs/commands/README.md).

This repo is the source of truth for the graphs I actually run. It is
not a dump of every third-party skill on the machine.

## Graph engineer

The main thread of `/ruver-developer`, `/ruver-qa`, `/ruver-triage`,
`/ruver-reviewer`, `/ruver-lstm`, `/ruver-bus`, and `/ruver-goal` is a
**graph engineer**, not an implementer.

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

## Commands

Index: [docs/commands](docs/commands/README.md). Each row is a page.

### Graphs (graph engineer)

| Command | When | More |
|---|---|---|
| `/ruver-developer` | Ticket, goal, or PR_BUG fix | [page](docs/commands/ruver-developer.md) |
| `/ruver-qa` | Browser QA + video comment | [page](docs/commands/ruver-qa.md) |
| `/ruver-triage` | Classify a QA finding | [page](docs/commands/ruver-triage.md) |
| `/ruver-reviewer` | Review a PR, diagnose CI | [page](docs/commands/ruver-reviewer.md) |
| `/ruver-lstm` | Incoming review, patch same branch | [page](docs/commands/ruver-lstm.md) |
| `/ruver-bus` | Resume stack / QA slot | [page](docs/commands/ruver-bus.md) |
| `/ruver-goal` | Wake until QA+video on head SHA | [page](docs/commands/ruver-goal.md) |

Aliases: `/ruver_developer`, `/ruver_qa`, `/ruver_triage`,
`/ruver_reviewer`, `/ruver_lstm`, `/ruver_bus`, `/ruver_goal`.

### Engines

| Command | When | More |
|---|---|---|
| `/ruver-feature-delivery` (`/ruver-fd`) | Grill → TDD → draft PR, CI green | [page](docs/commands/ruver-feature-delivery.md) |
| `/ruver-code-review` | One GitHub review artifact | [page](docs/commands/ruver-code-review.md) |

Prefer `/ruver-developer` over raw `/ruver-fd` when you also want
MERGEABLE + QA. Prefer `/ruver-reviewer` over raw `/ruver-code-review`
when CI / mergeability need a graph around the engine.

### Branch helpers

| Command | When | More |
|---|---|---|
| `/ruver-validate-branch` | Local gates, then ask before push | [page](docs/commands/ruver-validate-branch.md) |
| `/ruver-create-pr-frontend` | Draft FE PR body (does not open) | [page](docs/commands/ruver-create-pr.md) |
| `/ruver-create-pr-backend` | Draft BE PR body (does not open) | [page](docs/commands/ruver-create-pr.md) |

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

Skills are the same names as the [commands](#commands) above. Deep
pages live under [docs/commands](docs/commands/README.md). Source:
`plugins/ruver/skills/<name>/`.

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
  docs/commands/              # one page per slash command
  plugins/ruver/
    HOST.md
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
