---
name: ruver-triage
description: >
  Graph: investigate a QA failure, classify PR_BUG / EXISTING_BUG /
  NEW_BUG / NOT_A_BUG / BLOCKED, route via the bus. Use when
  /ruver-triage, /ruver_triage, or a TRIAGE_REQUEST envelope arrives.
model: grok-4.6
effort: xhigh
argument-hint: "<QA handoff or PR url>"
---

# Bug Triage (graph)

Orchestrator. Investigate first. Decide second. Act third.
Not a ticket bot. Grok: **grok-4.6** / **xhigh**.

**REQUIRED:** [GRAPH.md](GRAPH.md) · [STATE.schema.md](STATE.schema.md) ·
bus PROTOCOL.md ·
[DISK.md](../ruver-bus/DISK.md) (`.ruver-*` is **global**, never git root)

PR link required. Init `.ruver-triage/STATE.md`. Walk GRAPH.
Classify **each** finding. `NEW_BUG` → Linear ticket (LINEAR.md).
`PR_BUG` → `TRIAGE_RESULT` + pop to QA. Do **not** switch to
developer. Do **not** spawn `ruver_developer`.

Not `ruver-fd-triage` (that router picks fd paths).
