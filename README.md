# Skills

Agent graphs I run every day on **Grok**, **Claude Code**, **Codex**,
and **Cursor**. Delivery, QA, review, incoming review comments.

```text
/ruver-developer DEV-1234
/ruver-reviewer https://github.com/org/repo/pull/99
/ruver-lstm https://github.com/org/repo/pull/99
/ruver-qa https://github.com/org/repo/pull/99
```

This is the source of truth for the graphs I actually run. It is not a
dump of every third-party skill on the machine.

Formerly [`ruverd/ai-skills`](https://github.com/ruverd/ai-skills).
GitHub redirects the old URL.

## Installation (30-second setup)

Two ways in. **Plugin** installs the whole set as a managed bundle.
**`install.sh`** (or [skills.sh](https://skills.sh)) copies / links
editable skill files into your agent homes so slash names stay flat
(`/ruver-developer`, not `/graphs/ruver-developer`). Pick one.

### 1. Get the skills

**Symlink install (any harness)**

```bash
git clone https://github.com/ruverd/skills.git ~/Developer/skills
~/Developer/skills/install.sh
```

```bash
./install.sh --dry-run
./install.sh --plugin          # also register the Grok marketplace
./install.sh --uninstall
```

That flattens `skills/{graphs,engines,branch}/<name>` into:

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

**Grok plugin**

```bash
grok plugin marketplace add ruverd/skills
grok plugin install ruver --trust
```

**Claude Code**

```bash
claude plugins marketplace add ruverd/skills
claude plugins install ruver
```

Or, from inside a session: `/plugin install ruver` after adding the
marketplace.

**Codex, Cursor, and other agents**

```bash
npx skills@latest add ruverd/skills
```

Pick the skills you want, and which coding agents to install them on.

### 2. Restart the session

Then run a graph:

```text
/ruver-developer
```

## Graph engineer

The main thread of `/ruver-developer`, `/ruver-qa`, `/ruver-triage`,
`/ruver-reviewer`, `/ruver-lstm`, `/ruver-bus`, and `/ruver-goal` is a
**graph engineer**, not an implementer.

It walks a GRAPH (nodes + edges). It writes STATE under `~/.ruver`.
It spawns a **worker** when a node must touch product code. It never
opens `src/` itself.

| Layer | Lives in | Example |
|---|---|---|
| Graph | `skills/*/*/GRAPH.md` | admit → deliver → mergeable → QA |
| Host | [`HOST.md`](HOST.md) | how *this* harness spawns a child or wakes later |
| Product | the target repo `AGENTS.md` | test command, reviewers, Linear team |

A graph that says `spawn_subagent`, `model: grok-4.6`, or a company's
GitHub handles has leaked. Host APIs stay in HOST.md. Product policy
stays in the repo you are in.

Full write-up: [docs/GRAPH_ENGINEER.md](docs/GRAPH_ENGINEER.md).
Architecture: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).
Command pages: [docs/commands](docs/commands/README.md).

## Reference

These split on one axis: who can invoke them. **User-invoked** skills
are reachable when you type them (e.g. `/ruver-developer`); their job
is to orchestrate. **Model-invoked** skills can be invoked by you *or*
reached for automatically when the task fits. A user-invoked graph may
load a model-invoked skill or an engine, but it never spawns another
graph as a child.

Deep pages live under [docs/commands](docs/commands/README.md).

### Graphs

Main-thread graph engineer. Source: [`skills/graphs`](skills/graphs).

**User-invoked**

- **[ruver-developer](skills/graphs/ruver-developer/SKILL.md)** (`/ruver-developer`): Ticket, goal, or PR_BUG fix. Draft PR, MERGEABLE, then QA. [page](docs/commands/ruver-developer.md)
- **[ruver-qa](skills/graphs/ruver-qa/SKILL.md)** (`/ruver-qa`): Exercise a PR in the browser. Comment with video. [page](docs/commands/ruver-qa.md)
- **[ruver-triage](skills/graphs/ruver-triage/SKILL.md)** (`/ruver-triage`): Classify a QA finding. [page](docs/commands/ruver-triage.md)
- **[ruver-reviewer](skills/graphs/ruver-reviewer/SKILL.md)** (`/ruver-reviewer`): Review a PR. Diagnose CI. [page](docs/commands/ruver-reviewer.md)
- **[ruver-lstm](skills/graphs/ruver-lstm/SKILL.md)** (`/ruver-lstm`): Incoming review. Patch the same branch. [page](docs/commands/ruver-lstm.md)
- **[ruver-goal](skills/graphs/ruver-goal/SKILL.md)** (`/ruver-goal`): Wake until QA + video on the head SHA. [page](docs/commands/ruver-goal.md)

**Model-invoked**

- **[ruver-bus](skills/graphs/ruver-bus/SKILL.md)** (`/ruver-bus`): Shared envelopes, stack, and the QA slot. Graphs talk through files, not nested agents. [page](docs/commands/ruver-bus.md)

Aliases: `/ruver_developer`, `/ruver_qa`, `/ruver_triage`,
`/ruver_reviewer`, `/ruver_lstm`, `/ruver_bus`, `/ruver_goal`.

### Engines

Called by a graph, or run alone. Source: [`skills/engines`](skills/engines).

**User-invoked**

- **[ruver-feature-delivery](skills/engines/ruver-feature-delivery/SKILL.md)** (`/ruver-feature-delivery`, `/ruver-fd`): Grill → spec → tickets → TDD → draft PR, CI green. [page](docs/commands/ruver-feature-delivery.md)
- **[ruver-code-review](skills/engines/ruver-code-review/SKILL.md)** (`/ruver-code-review`): One GitHub review artifact. [page](docs/commands/ruver-code-review.md)

Prefer `/ruver-developer` over raw `/ruver-fd` when you also want
MERGEABLE + QA. Prefer `/ruver-reviewer` over raw `/ruver-code-review`
when CI / mergeability need a graph around the engine.

### Branch

Local helpers. Source: [`skills/branch`](skills/branch).

**User-invoked**

- **[ruver-validate-branch](skills/branch/ruver-validate-branch/SKILL.md)** (`/ruver-validate-branch`): Local gates, then ask before push. [page](docs/commands/ruver-validate-branch.md)
- **[ruver-create-pr-frontend](skills/branch/ruver-create-pr-frontend/SKILL.md)** (`/ruver-create-pr-frontend`): Draft an FE PR body. Does not open it. [page](docs/commands/ruver-create-pr.md)
- **[ruver-create-pr-backend](skills/branch/ruver-create-pr-backend/SKILL.md)** (`/ruver-create-pr-backend`): Draft a BE PR body. Does not open it. [page](docs/commands/ruver-create-pr.md)

`ruver-create-pr-*` are empath-specific extras. The core graphs are not.

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
[`ruver-bus/DISK.md`](skills/graphs/ruver-bus/DISK.md).

Workers (`ruver-fd-coder`, tester, shipper, …) write product code.
Graph names (`ruver_developer`, `ruver_qa`, …) are **roles for the
main thread**. Do not spawn those. See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## Layout

```text
skills/                         # this repo
  README.md
  HOST.md                       # harness primitives
  install.sh
  plugin.json
  docs/GRAPH_ENGINEER.md
  docs/ARCHITECTURE.md
  docs/commands/                # one page per slash command
  skills/
    graphs/                     # main-thread graph engineer
    engines/                    # delivery + review engines
    branch/                     # local validation + PR body
  agents/                       # fd workers + graph roles
  commands/                     # slash aliases
```

In git, skills are nested by category (same idea as
[mattpocock/skills](https://github.com/mattpocock/skills)). After
`install.sh`, they flatten so `/ruver-developer` still works. Graphs
in the same category keep `../ruver-bus/...`. Cross-category links
go through `../../engines/...` (and resolve via the real path).

## What this repo does not include

- Third-party skills (pstack, caveman, Cursor team kit, cmux, …).
- Runtime `.ruver-*` state. That stays in `~/.ruver/`.

LSTM expects `receiving-code-review` and `unslop` if those skills are
installed. QA expects `gh`, a browser, and Playwright on the target app.

## Add or edit a skill

Follow [docs/GRAPH_ENGINEER.md](docs/GRAPH_ENGINEER.md). Short version:

1. Folder under `skills/graphs/<name>/` (or `engines/` / `branch/`).
2. Relative links only. No `~/.claude`, `~/.grok`, `~/.codex`.
3. Host primitives → HOST.md. Product policy → the target repo.
4. Add the path to `plugin.json`, then `./install.sh` and commit.

```bash
grok plugin validate .
```

## License

MIT. See [LICENSE](LICENSE).
