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
| `/goal` | Keep going until QA evidence lands on the head SHA |
| `/ruver-triage` | Classify a QA finding. Not a ticket bot |
| `/memory` | Durable prefs outside git (chat language, reviewers) |

Short slashes (`/developer`, `/qa`, `/reviewer`, `/lstm`, `/goal`,
`/memory`) are
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

That clones the repo, links `skills/<name>` into
`~/.agents/skills` (and Grok, Claude, Cursor, Codex), and puts `ruver`
on your PATH.

```bash
ruver update     # git pull --ff-only main, then relink
ruver status
ruver report     # wall time and laps per graph node
ruver uninstall
```

`ruver report` reads the run ledger the graphs write as they walk: wall time and
lap count per node, plus the age of the QA claim. See
[Measuring it](#measuring-it).

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
([PRODUCT.md](skills/ruver-feature-delivery/PRODUCT.md)).
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
| Graph | `skills/<name>/GRAPH.md` | admit → deliver → mergeable → QA |
| Host | [`ruver-host`](skills/ruver-host/SKILL.md) | how *this* harness spawns a child or wakes later |
| Product | target repo `AGENTS.md` + [PRODUCT.md](skills/ruver-feature-delivery/PRODUCT.md) | test command, reviewers, sibling repos |

A graph that says `spawn_subagent`, `model: grok-4.6`, or a company's
GitHub handles has leaked. Host APIs stay in `ruver-host`. Product policy
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

Main-thread graph engineer. `category: graph`. Source: [`skills/`](skills/README.md).

**User-invoked**

- **[ruver-developer](skills/ruver-developer/SKILL.md)** (`/developer`, `/ruver-developer`): Ticket, goal, or PR_BUG fix. Draft PR, MERGEABLE, then QA. [page](docs/commands/ruver-developer.md)
- **[ruver-qa](skills/ruver-qa/SKILL.md)** (`/qa`, `/ruver-qa`): Exercise a PR (browser, e2e, or HTTP). Comment with evidence. [page](docs/commands/ruver-qa.md)
- **[ruver-triage](skills/ruver-triage/SKILL.md)** (`/ruver-triage`): Classify a QA finding. [page](docs/commands/ruver-triage.md)
- **[ruver-reviewer](skills/ruver-reviewer/SKILL.md)** (`/reviewer`, `/ruver-reviewer`): Review a PR. Diagnose CI. [page](docs/commands/ruver-reviewer.md)
- **[ruver-lstm](skills/ruver-lstm/SKILL.md)** (`/lstm`, `/ruver-lstm`): Incoming review. Patch the same branch. [page](docs/commands/ruver-lstm.md)
- **[ruver-goal](skills/ruver-goal/SKILL.md)** (`/goal`, `/ruver-goal`): Wake until QA evidence on the head SHA. [page](docs/commands/ruver-goal.md)

### Protocol (model-invoked)

Not a graph. It has no nodes and walks no edges. The graphs load it by name for
the shared envelope, stack and QA-slot rules.

- **[ruver-bus](skills/ruver-bus/SKILL.md)** (`/ruver-bus`): Shared envelopes, stack, and the QA slot. Graphs talk through files, not nested agents. [page](docs/commands/ruver-bus.md)

### Lib

**User-invoked**

- **[ruver-memory](skills/ruver-memory/SKILL.md)** (`/memory`, `/ruver-memory`): Chat language, confirmed reviewers, open questions. Outside git. [page](docs/commands/memory.md)

**Model-invoked**

- **[ruver-host](skills/ruver-host/SKILL.md)**: the host contract. Maps `load_skill`, `spawn_worker`, `worktree`, `schedule_wake`, `session_model` and the optional MCP capabilities onto whatever harness you are on. A graph loads it by name when a node mentions a primitive.
- The bundled primitives (`unslop`, `tdd`, `how`, `why`, `grill-*`, `principle-*`, …) reach themselves when the task fits. Origins: [External references](#external-references).

### Engines

Called by a graph, or run alone. `category: engine`. Source: [`skills/`](skills/README.md).

**User-invoked**

- **[ruver-feature-delivery](skills/ruver-feature-delivery/SKILL.md)** (`/ruver-feature-delivery`, `/ruver-fd`): Grill → spec → tickets → TDD → draft PR, CI green. [page](docs/commands/ruver-feature-delivery.md)
- **[ruver-code-review](skills/ruver-code-review/SKILL.md)** (`/ruver-code-review`): One GitHub review artifact. [page](docs/commands/ruver-code-review.md)

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

### What bounds a run

A run that fails does not fail quietly, and a run that dies does not take the
queue with it.

| Bound | Default | What it stops |
|---|---|---|
| `qa_lease_minutes` | 90 | A QA that died `handed_off`, `escalated`, or with its session used to hold the single QA slot for good, parking every later PR behind a queue position that would never move. A claim past the lease is free, and the next QA takes it over and says so |
| `qa_fix_loops` | 2 | QA FAIL → fix → QA is the most expensive loop here: a full QA, a triage, and a fix per lap. A finding id that repeats across laps escalates at once, because a fix that did not hold will not hold on the next lap either |
| `ci_fix_loops` · `review_fix_loops` · `test_fix_loops` | 5 · 2 · 2 | The cheaper loops inside delivery |
| stack depth | 3 | `developer → qa → triage` is the deepest real chain. A fourth frame means an edge points back into a graph already running, so it is a cycle |

Every QA lap is appended to `qa_verdict_log` in the developer STATE, so a loop
is readable after the fact rather than inferred.

### Measuring it

The graphs append one row per transition to `.ruver-bus/RUN_LOG.tsv` — two lines
per node, no LLM cost. `ruver report` turns that into wall time and lap count
per `graph/node`, widest first:

```text
repo app
  graph/node                         run     total   longest
  qa/execute                           2    50m00s    26m40s   <- 2 laps
  developer/fix                        1    10m00s    10m00s
  QA lease: qa-pr-77 held 150m, cap 90m - dead claim, the queue is stuck
```

Nothing gates on it. The table above is the control; this is the instrument.
Token counts are deliberately absent: a node cannot see its own usage, and an
invented number is worse than none, so
[`LEDGER.md`](skills/ruver-bus/LEDGER.md) points at the host transcript instead.

Runtime state:

```text
~/.ruver/memory.md                       # you, every repo
~/.ruver/<slug>/memory.md                # this git toplevel
~/.ruver/<slug>/.ruver-bus/
                  STACK.md               # which graph is active
                  ENVELOPE.md            # the message being handed over
                  JOBS.md                # workers + the QA lease
                  RUN_LOG.tsv            # transitions, timing, laps
~/.ruver/<slug>/.ruver-developer/        # one dir per graph or engine
~/.ruver/<slug>/.ruver-qa/               # .ruver-triage, -reviewer, -lstm,
                                         # -goal, -code-review,
                                         # -feature-delivery
```

`<slug>` is the git toplevel with `/` replaced by `-`. Details:
[`ruver-bus/DISK.md`](skills/ruver-bus/DISK.md).

Workers (`ruver-fd-coder`, tester, shipper, …) write product code.
Graph names (`ruver_developer`, `ruver_qa`, …) are **roles for the
main thread**. Do not spawn those. See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## Layout

```text
skills/                         # this repo
  README.md
  install.sh
  plugin.json
  docs/GRAPH_ENGINEER.md
  docs/ARCHITECTURE.md
  docs/commands/                # one page per slash command
  skills/                       # one flat directory per skill
    ruver-developer/            # category: graph
    ruver-feature-delivery/     # category: engine
    ruver-host/                 # category: lib, harness primitives
    unslop/                     # category: lib
    …
  agents/                       # fd workers + graph roles
  commands/                     # slash aliases
```

One flat directory per skill, in git and after install alike. That is what
makes `../other-skill/FILE.md` resolve in both places, and `tests/repo.sh`
fails any link that leaves the skills root. `category` in the frontmatter says
whether a skill is a graph, an engine, or a lib primitive. Slash names stay
so `/ruver-developer` still works. Every skill is a sibling, so cross-skill links are `../<name>/FILE.md` and
resolve identically in git and after install.

## What this repo does not include

- Runtime `.ruver-*` state. That stays in `~/.ruver/`.
- Optional extras you may already have (caveman, cmux). The graphs
  do not load them.

## Add or edit a skill

Follow [docs/GRAPH_ENGINEER.md](docs/GRAPH_ENGINEER.md). Short version:

1. Folder under `skills/<name>/` with `category: graph | engine | lib`.
2. Relative links only. No `~/.claude`, `~/.grok`, `~/.codex`.
3. Host primitives → [ruver-host](skills/ruver-host/SKILL.md). Product policy → [PRODUCT.md](skills/ruver-feature-delivery/PRODUCT.md) plus the target repo.
4. Add the path to **both** `plugin.json` and `.claude-plugin/plugin.json`,
   and the name to `.grok-plugin/plugin-index.json`. `tests/repo.sh` fails if
   any of them disagrees with the tree.
5. Run `ruver setup` (or `./install.sh setup`), then `bash tests/repo.sh` and
   `bash tests/install.sh`, then commit.

```bash
grok plugin validate .
```

## External references

Primitives the graphs load live in
[`skills/`](skills/README.md). They are copied into this repo
so a clone is enough. Full list and licenses:
[THIRD_PARTY.md](THIRD_PARTY.md).

| Origin | Copied skills |
|---|---|
| [mattpocock/skills](https://github.com/mattpocock/skills) | `grill-with-docs`, `grill-me`, `diagnose`, `to-prd`, `to-issues` |
| [pstack](https://github.com/poteto/pstack) | `unslop`, `tdd`, `how`, `why`, `principle-*`, … |
| [superpowers](https://github.com/obra/superpowers) | `receiving-code-review` |
| Cursor team kit | `thermo-nuclear-code-quality-review` |

## License

MIT. See [LICENSE](LICENSE). Bundled third-party copies keep
their original licenses.
