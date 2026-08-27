# Skills

A small circuit for shipping software with a coding agent: ticket →
draft PR → CI green → QA in the browser (with video) → incoming
review patched on the same branch. Works on **Grok**, **Claude
Code**, **Codex**, and **Cursor**.

The session you talk to is a **graph engineer**, not an implementer.
It walks a GRAPH (nodes + edges). It writes state under `~/.ruver`.
When a node must touch product code, it spawns a **worker**. Graphs
talk through files on a bus. They never nest as child agents. They
never merge.

TDD on behavior change. ASK the user only as a last resort.

```text
/developer DEV-1234
/qa https://github.com/org/repo/pull/99
/reviewer https://github.com/org/repo/pull/99
/lstm https://github.com/org/repo/pull/99
```

| You type | What happens |
|---|---|
| `/developer` | Grill, spec, tickets, TDD, draft PR, CI, then QA |
| `/qa` | Exercise the PR in the browser. Comment with video |
| `/reviewer` | Review the PR. Diagnose CI |
| `/lstm` | Incoming review. Patch the same branch |
| `/ruver-triage` | Classify a QA finding. Not a ticket bot |

Short slashes (`/developer`, `/qa`, `/reviewer`, `/lstm`) are aliases
of `/ruver-*`. Skill ids stay `ruver-*`. This repo is those graphs,
not a dump of every third-party skill on a machine.

## Installation (30-second setup)

Two ways in. **Plugin** installs the whole set as a managed bundle.
**[skills.sh](https://skills.sh/ruverd/skills)** copies editable skill
files into your agent homes so slash names stay flat
(`/ruver-developer`, not `/graphs/ruver-developer`). Pick one.

### 1. Get the skills

**Grok**

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

**From a clone**

```bash
git clone https://github.com/ruverd/skills.git
cd skills
./install.sh
```

```bash
./install.sh --dry-run
./install.sh --plugin
./install.sh --uninstall
```

That flattens `skills/{graphs,engines,lib}/<name>` into
`~/.agents/skills`, plus the matching homes for Grok, Claude, Cursor,
and Codex.

Runtime disk is **`~/.ruver/<slug>/`**, shared across hosts. If
`~/.grok/ruver` already exists, install.sh links `~/.ruver` to it so
live jobs keep running.

### 2. Restart the session

Then run a graph:

```text
/developer
```

## Dependencies

Not skills. They must already exist on the machine, in the target
app, and in the agent session.

**CLI / app**

| Need | Used by |
|---|---|
| [`gh`](https://cli.github.com/) authenticated | `/developer`, `/reviewer`, `/lstm`, `/qa` |
| A browser | `/qa` |
| Playwright on the target app | `/qa` |

**Links in the goal**

If you pass a ticket, spec, or design URL, this session must be able
to open it (MCP or equivalent). That can be Linear, Notion, Jira,
GitHub Issues, Figma, Sentry, or any other tracker. There is no
fixed vendor. A URL we cannot read stops the graph; it does not
invent the ticket.

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

- **[ruver-developer](skills/graphs/ruver-developer/SKILL.md)** (`/developer`, `/ruver-developer`): Ticket, goal, or PR_BUG fix. Draft PR, MERGEABLE, then QA. [page](docs/commands/ruver-developer.md)
- **[ruver-qa](skills/graphs/ruver-qa/SKILL.md)** (`/qa`, `/ruver-qa`): Exercise a PR in the browser. Comment with video. [page](docs/commands/ruver-qa.md)
- **[ruver-triage](skills/graphs/ruver-triage/SKILL.md)** (`/ruver-triage`): Classify a QA finding. [page](docs/commands/ruver-triage.md)
- **[ruver-reviewer](skills/graphs/ruver-reviewer/SKILL.md)** (`/reviewer`, `/ruver-reviewer`): Review a PR. Diagnose CI. [page](docs/commands/ruver-reviewer.md)
- **[ruver-lstm](skills/graphs/ruver-lstm/SKILL.md)** (`/lstm`, `/ruver-lstm`): Incoming review. Patch the same branch. [page](docs/commands/ruver-lstm.md)
- **[ruver-goal](skills/graphs/ruver-goal/SKILL.md)** (`/ruver-goal`): Wake until QA + video on the head SHA. [page](docs/commands/ruver-goal.md)

**Model-invoked**

- **[ruver-bus](skills/graphs/ruver-bus/SKILL.md)** (`/ruver-bus`): Shared envelopes, stack, and the QA slot. Graphs talk through files, not nested agents. [page](docs/commands/ruver-bus.md)

### Engines

Called by a graph, or run alone. Source: [`skills/engines`](skills/engines).

**User-invoked**

- **[ruver-feature-delivery](skills/engines/ruver-feature-delivery/SKILL.md)** (`/ruver-feature-delivery`, `/ruver-fd`): Grill → spec → tickets → TDD → draft PR, CI green. [page](docs/commands/ruver-feature-delivery.md)
- **[ruver-code-review](skills/engines/ruver-code-review/SKILL.md)** (`/ruver-code-review`): One GitHub review artifact. [page](docs/commands/ruver-code-review.md)

Prefer `/ruver-developer` over raw `/ruver-fd` when you also want
MERGEABLE + QA. Prefer `/ruver-reviewer` over raw `/ruver-code-review`
when CI / mergeability need a graph around the engine.

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
    lib/                        # bundled primitives (unslop, grill, tdd, …)
  agents/                       # fd workers + graph roles
  commands/                     # slash aliases
```

Skills are nested by category in git. After `install.sh`, they flatten
so `/ruver-developer` still works. Graphs in the same category keep
`../ruver-bus/...`. Cross-category links go through
`../../engines/...` (and resolve via the real path).

## What this repo does not include

- Runtime `.ruver-*` state. That stays in `~/.ruver/`.
- Optional extras you may already have (caveman, cmux). The graphs
  do not load them.

## Add or edit a skill

Follow [docs/GRAPH_ENGINEER.md](docs/GRAPH_ENGINEER.md). Short version:

1. Folder under `skills/graphs/<name>/` (or `engines/`).
2. Relative links only. No `~/.claude`, `~/.grok`, `~/.codex`.
3. Host primitives → HOST.md. Product policy → the target repo.
4. Add the path to `plugin.json`, then `./install.sh` and commit.

```bash
grok plugin validate .
```

## External references

Primitives the graphs load live in
[`skills/lib/`](skills/lib/README.md). They are copied into this repo
so a clone is enough. Full list and licenses:
[THIRD_PARTY.md](THIRD_PARTY.md).

| Origin | Copied skills |
|---|---|
| [mattpocock/skills](https://github.com/mattpocock/skills) | `grill-with-docs`, `grill-me`, `diagnose`, `to-prd`, `to-issues` |
| [pstack](https://github.com/poteto/pstack) | `unslop`, `tdd`, `how`, `why`, `principle-*`, … |
| [superpowers](https://github.com/obra/superpowers) | `receiving-code-review` |
| Cursor team kit | `thermo-nuclear-code-quality-review` |

## License

MIT. See [LICENSE](LICENSE). Bundled copies in `skills/lib/` keep
their original licenses.
