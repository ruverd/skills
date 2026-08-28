---
name: ruver-triage
category: graph
description: >
  Graph: investigate a QA failure, classify PR_BUG / EXISTING_BUG /
  NEW_BUG / NOT_A_BUG / BLOCKED, route via the bus. Use when
  /ruver-triage, or a TRIAGE_REQUEST envelope arrives.
argument-hint: "<QA handoff or PR url>"
---

# Bug Triage (graph)

Orchestrator. Investigate first. Decide second. Act third.
Not a ticket bot. Use the session model; high effort if the host
exposes it ([HOST.md](../../../HOST.md)).

**REQUIRED:** [GRAPH.md](GRAPH.md) · [STATE.schema.md](STATE.schema.md) ·
bus PROTOCOL.md · `ruver-memory` ·
[DISK.md](../ruver-bus/DISK.md) (`.ruver-*` is **global**, never git root)

Chat: `ruver-memory`. Unslop always. PR link required. Init `.ruver-triage/STATE.md`. Walk GRAPH.
Classify **each** finding. `NEW_BUG` → Linear ticket (LINEAR.md).
`PR_BUG` → `TRIAGE_RESULT` + pop to QA. Do **not** switch to
developer. Do **not** spawn `ruver_developer`.

Not `ruver-fd-triage` (that router picks fd paths).
