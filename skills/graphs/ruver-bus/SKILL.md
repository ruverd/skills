---
name: ruver-bus
description: >
  Shared bus for the ruver agent graphs (developer, qa, triage, reviewer, lstm).
  Use when switching graphs, writing or reading a .ruver-bus envelope, or
  resuming a stacked handoff between those agents.
argument-hint: "<resume | status>"
user-invocable: true
---

# Ruver bus

Five graphs, one session. They **do not nest**.

```
developer ⇄ qa ⇄ triage
     ⇄ reviewer
     ⇄ lstm
```

Communication = files under **`.ruver-bus/`** in the **global** home
([DISK.md](DISK.md)) — never the git root.
Protocol: [PROTOCOL.md](PROTOCOL.md). Jobs / QA queue: [JOBS.md](JOBS.md).

## Who orchestrates

The **main thread** is the only graph runner.

| Situation | Action |
|---|---|
| Main, outbound edge | Write envelope → push stack → **load** the target graph SKILL/GRAPH and continue |
| Already a subagent | Write envelope, return. Do **not** spawn a graph |
| Resume / `/ruver-bus` | Read `STACK.md` + latest envelope → load that graph |

**Never** `spawn_worker` with type `ruver_qa` / `ruver_triage` /
`ruver_developer` / `ruver_reviewer` / `ruver_lstm`. Those names are
graphs (main-thread roles). Overflow developer/reviewer/lstm work =
one general-purpose worker + worktree ([JOBS.md](JOBS.md),
[HOST.md](../../../HOST.md)). Never a second QA worker.

## Resume

```text
/ruver-bus resume
```

1. Read `.ruver-bus/STACK.md` (**last line** = active graph).
2. Read `.ruver-bus/ENVELOPE.md`.
3. `load_graph` the last STACK line (`ruver-<name>` SKILL.md + GRAPH.md).
4. Continue from that graph's STATE. Do not restart.
5. Also print `JOBS.md`: `qa_active`, `qa_waiting`, worker rows.

## Chat

PT-BR curto: `S: bus <from>→<to> <type>` · `P: grafo ativo` ·
`qa_active` / fila.
