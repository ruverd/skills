# Graph engineer

A graph engineer writes **how the agent works**. Not the product.

The main thread of `/ruver-developer`, `/ruver-qa`, `/ruver-triage`,
`/ruver-reviewer`, `/ruver-lstm`, `/ruver-bus`, and `/ruver-goal`
**is** that role. It walks a GRAPH. It writes STATE. It does not
open `src/` and type the feature.

Command pages: [commands/](commands/README.md).

## Three layers

| Layer | Where it lives | What it names |
|---|---|---|
| **Graph** | this repo (`skills/{graphs,engines,lib}/`, `GRAPH.md`) | nodes, edges, stop conditions, envelopes |
| **Host** | [HOST.md](../HOST.md) | how *this* harness spawns a child, wakes later, isolates a worktree |
| **Product** | the target repo `AGENTS.md` / `CLAUDE.md` | test command, reviewers, Linear team, design system |

A graph that says `spawn_subagent` or `model: grok-4.6` or
`reviewers: izaiasneto4` is no longer a graph. It is a host or a
product leaking in.

## What you ship

For each graph:

- `SKILL.md` — when to run, invariants, what the orchestrator never does
- `GRAPH.md` — nodes and edges
- `STATE.schema.md` + `templates/STATE.md`
- `nodes/*.md` — one file per node
- bus types, if it talks to another graph ([PROTOCOL.md](../skills/graphs/ruver-bus/PROTOCOL.md))

Worker contracts (`agents/ruver-fd-coder.md`, …) are **not** graphs.
They implement one ticket. The graph engineer writes the contract;
the worker runs it.

## Main thread

```
User slash / envelope
        │
        ▼
  Graph engineer (this session)
        │
        ├── load sibling skill by name
        ├── read/write $RUVER_ROOT (never the git root)
        ├── spawn ONE worker when the node says implement / test / review
        └── bus switch (envelope + stack) when the edge leaves this graph
```

Never spawn another **graph** as a child (`ruver_qa`, `ruver_developer`,
…). Load it on this thread after the bus write. See HOST.md
`load_graph` vs `spawn_worker`.

## Adding a graph

1. Folder under `skills/graphs/<name>/` (engines go in `skills/engines/`,
   primitives in `skills/lib/`).
2. Relative links only. Same category: `../ruver-bus/JOBS.md`. Cross
   category: `../../engines/ruver-feature-delivery/...`. No `~/.claude`,
   `~/.grok`, `~/.codex`, `~/.agents`.
3. Need a child agent? Call it `spawn_worker` and point at HOST.md.
4. Need a later turn (CI)? Call it `schedule_wake` and point at HOST.md.
5. Product policy (who reviews, which test binary) comes from the
   **current repo**, not from this plugin.
6. List the path in `plugin.json`.

Then `./install.sh` and a commit. Slash names stay the skill folder
name (`/ruver-developer`) because install.sh flattens categories.
