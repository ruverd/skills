# Skills

Skills for coding agents. Give one a ticket or a local goal and it
writes the code, opens a draft PR, exercises the change (browser, e2e,
or HTTP), and handles review.

The session you talk to is a **graph engineer**, not an implementer.
It walks a GRAPH (nodes + edges). It writes state under `~/.ruver`.
When a node must touch product code, it spawns a **worker**. Graphs
talk through files on a bus. They never nest as child agents. They
never merge.

TDD on behavior change. ASK the user only as a last resort.

```text
/developer ABC-123
/qa https://github.com/org/repo/pull/99
/reviewer https://github.com/org/repo/pull/99
/lstm https://github.com/org/repo/pull/99
```

| You type | What happens |
|---|---|
| `/developer` | Grill, spec, tickets, TDD, draft PR, CI, then QA |
| `/qa` | Exercise the PR (browser, e2e, or HTTP). Comment with evidence |
| `/reviewer` | Review the PR. Diagnose CI |
| `/lstm` | Incoming review. Patch the same branch |
| `/ruver-triage` | Classify a QA finding. Not a ticket bot |
| `/memory` | Durable prefs outside git (chat language, reviewers) |

Short slashes (`/developer`, `/qa`, `/reviewer`, `/lstm`, `/memory`) are
aliases of `/ruver-*`. Skill ids stay `ruver-*`. This repo is those
graphs, not a dump of every third-party skill on a machine.

## Installation

```bash
curl -fsSL https://raw.githubusercontent.com/ruverd/skills/main/install.sh | bash
```

Needs `git` and `curl`. macOS, Linux, and WSL. No Node.

Install works by symlinking, and `ruver update` relies on those links to pick
up new commits. Windows Git Bash turns `ln -s` into a silent copy unless
Developer Mode is on and `MSYS=winsymlinks:nativestrict` is set, so `setup`
checks whether symlinks actually work and refuses rather than installing
something that will never update. WSL is the supported path on Windows.

That clones the repo, flattens `skills/{graphs,engines,lib}/<name>` into
`~/.agents/skills` (and Grok, Claude, Cursor, Codex), and puts `ruver`
on your PATH.

```bash
ruver update     # git pull --ff-only main, then relink
ruver status
ruver uninstall
```

**This checkout** (developing the repo): `./install.sh setup`
points `ruver` at this tree. `ruver update` is `git pull` here.

**Plugin** (optional, not flattened the same way). Add the marketplace first,
then install `ruver` from it:

```bash
# Claude Code
claude plugin marketplace add ruverd/skills
claude plugin install ruver@skills

# Grok
grok plugin marketplace add ruverd/skills
grok plugin install ruver --trust
```

Inside a Claude Code session the same two steps are `/plugin marketplace add
ruverd/skills` then `/plugin install ruver@skills`. `skills` is the marketplace
name from `.claude-plugin/marketplace.json`; `ruver` is the plugin in it.

The plugin route auto-updates through the host, but it does not flatten skills
into slash names the way `ruver setup` does. Do not combine plugin and
`ruver setup` on the same host. `ruver status` warns if both are present.

Runtime disk is **`~/.ruver/`**, including `memory.md` (`/memory`).
Install never creates `memory.md`. If `~/.grok/ruver` already exists,
setup links `~/.ruver` to it so live jobs keep running.

### Restart the session

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
| `gh` or `glab` authenticated (the forge this repo uses) | `/developer`, `/reviewer`, `/lstm`, `/qa` |
| A browser | `/qa` on UI changes |
| The app's e2e runner if it has one (Playwright, Cypress, …) | `/qa` on UI |

Which of those you need is discovered per repo
([PRODUCT.md](skills/engines/ruver-feature-delivery/PRODUCT.md)).
A local goal does not need a tracker. API-only QA does not need a
browser. `--no-pr` or a git-only remote ships a commit, not a PR.

**Links in the goal**

If you pass a ticket, spec, or design URL, this session must be able
to open it (MCP or equivalent). That can be Linear, Notion, Jira,
GitHub Issues, Figma, Sentry, or any other tracker. There is no
fixed vendor. A URL we cannot read stops the graph; it does not
invent the ticket.

## Graph engineer

The main thread of `/ruver-developer`, `/ruver-qa`, `/ruver-triage`,
`/ruver-reviewer`, `/ruver-lstm`, and `/ruver-goal` is a **graph engineer**, not
an implementer. `/ruver-bus` is the protocol they share, not a graph of its own.

It walks a GRAPH (nodes + edges). It writes STATE under `~/.ruver`.
It spawns a **worker** when a node must touch product code. It never
opens `src/` itself.

| Layer | Lives in | Example |
|---|---|---|
| Graph | `skills/*/*/GRAPH.md` | admit → deliver → mergeable → QA |
| Host | [`HOST.md`](HOST.md) | how *this* harness spawns a child or wakes later |
| Product | target repo `AGENTS.md` + [PRODUCT.md](skills/engines/ruver-feature-delivery/PRODUCT.md) | test command, reviewers, sibling repos |

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
- **[ruver-qa](skills/graphs/ruver-qa/SKILL.md)** (`/qa`, `/ruver-qa`): Exercise a PR (browser, e2e, or HTTP). Comment with evidence. [page](docs/commands/ruver-qa.md)
- **[ruver-triage](skills/graphs/ruver-triage/SKILL.md)** (`/ruver-triage`): Classify a QA finding. [page](docs/commands/ruver-triage.md)
- **[ruver-reviewer](skills/graphs/ruver-reviewer/SKILL.md)** (`/reviewer`, `/ruver-reviewer`): Review a PR. Diagnose CI. [page](docs/commands/ruver-reviewer.md)
- **[ruver-lstm](skills/graphs/ruver-lstm/SKILL.md)** (`/lstm`, `/ruver-lstm`): Incoming review. Patch the same branch. [page](docs/commands/ruver-lstm.md)
- **[ruver-goal](skills/graphs/ruver-goal/SKILL.md)** (`/ruver-goal`): Wake until QA evidence on the head SHA. [page](docs/commands/ruver-goal.md)

### Protocol (model-invoked)

Not a graph. It has no nodes and walks no edges. The graphs load it by name for
the shared envelope, stack and QA-slot rules.

- **[ruver-bus](skills/graphs/ruver-bus/SKILL.md)** (`/ruver-bus`): Shared envelopes, stack, and the QA slot. Graphs talk through files, not nested agents. [page](docs/commands/ruver-bus.md)

### Lib (user-invoked)

- **[ruver-memory](skills/lib/ruver-memory/SKILL.md)** (`/memory`, `/ruver-memory`): Chat language, confirmed reviewers, open questions. Outside git. [page](docs/commands/memory.md)

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
~/.ruver/memory.md
~/.ruver/<slug>/memory.md
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

Skills are nested by category in git. After `ruver setup`, they flatten
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
3. Host primitives → HOST.md. Product policy → [PRODUCT.md](skills/engines/ruver-feature-delivery/PRODUCT.md) plus the target repo.
4. Add the path to `plugin.json`, then `ruver setup` (or `./install.sh setup`) and commit.

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
