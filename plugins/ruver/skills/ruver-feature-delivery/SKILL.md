---
name: ruver-feature-delivery
description: >
  Use when delivering a Linear ticket, bug, or chore end-to-end
  (implementation through draft PR with CI green) via
  /ruver-feature-delivery or /ruver-fd, or when resuming a run
  whose HANDOFF.md exists under $RUVER_ROOT/.ruver-feature-delivery/.
  Spine: grill-with-docs → spec → tickets → implement(tdd) → review.
  User-facing chat in Brazilian Portuguese. Unslop. Never write .ruver-* inside a repo.
---

# Ruver feature delivery

Orchestrator. Speak to the user in Brazilian Portuguese. Unslop. **No product code on the main thread.**

Load now:

- [GRAPH.md](GRAPH.md)
- [STATE.schema.md](STATE.schema.md)
- [ROUTING.md](ROUTING.md)
- [VOICE.md](VOICE.md)
- [PSTACK.md](PSTACK.md)
- [DECISION_POLICY.md](DECISION_POLICY.md)
- `ruver-bus` [DISK.md](../ruver-bus/DISK.md)

Spine (Matt Pocock + pstack, not Superpowers):

```
grill-with-docs → to-spec → to-tickets → implement(/tdd) → code-review
```

Adapted grill: [GRILL.md](GRILL.md). ASK the user only as a last resort.

## Quick start

```text
/ruver-fd DEV-1212
/ruver-fd DEV-1212: extra note
/ruver-fd null crash in MembersTable
/ruver-fd resume
/ruver-fd … --no-pr
```

Linear branch `feature/dev-xxxx` (or Linear `gitBranchName`).

## Orchestrator loop

**Resume:** read STATE + HANDOFF, **RECONCILE** (git/gh vs STATE, see HANDOFF.md), continue at the current node. If `waiting_user`, the user message is the ASK answer. Do not re-init. Do not re-run mcp_context / triage / grill branches that are already settled.

**Fresh:**

1. Init STATE under `$RUVER_ROOT/.ruver-feature-delivery/`.
2. `mcp_context` then `triage`. Critical MCP down → STOP. Do not invent.
3. Walk GRAPH. Grill / spec / tickets on the main thread. Spawn **one** node subagent at a time for implement / review / diagnose / tester / quality / shipper.
4. Never merge. Draft PR only from `shipper`.
5. Near context limit → `handoff`.

## Paths

| path / scope | When | How |
|---|---|---|
| **full_feature** | new behavior | grill → spec → tickets → TDD implement |
| **debug_fix** | bug | diagnose → one TDD ticket |
| **light_change** | chore | one ticket → one coder |
| **`scope: fullstack`** | FE and BE | Orca worktrees, same branch ([FULLSTACK.md](FULLSTACK.md)) |

Ship: review → tester → blast (not light) → **thermo fix all** → commit → push → draft PR
(reviewers and assignee: current repo `AGENTS.md` / git defaults)
→ **CI 100% green** (only then **delivered**).

## Intelligence

1. Route with evidence. Not full_feature on every bug.
2. DECIDE micro-choices. ASK only last-resort policy.
3. Bug: root cause **before** the fix. If it is a feature, re-route to grill.
4. Implementation **only** in a subagent. Main does not edit product code.
5. TDD on every behavior change. Thermo fix all before PR.
6. UI: DS of the repo; Figma if present; else copy recent same-type screens.
7. MCP: verify access. Critical offline → error in Brazilian Portuguese and stop.
8. Blocker: advance what you can → Draft Linear + contract comment → `waiting_blocker`.
9. Tokens: [TOKEN_ECONOMY.md](TOKEN_ECONOMY.md).
10. Limit near: [HANDOFF.md](HANDOFF.md).

## Files

Load on demand. This list is the index.

```
ruver-feature-delivery/
├── SKILL.md GRAPH.md ROUTING.md PSTACK.md GRILL.md VOICE.md
├── DECISION_POLICY.md TDD.md IMPLEMENTATION.md
├── MCP_CONTEXT.md LINEAR.md BLOCKERS.md FULLSTACK.md
├── UI_DESIGN_SYSTEM.md CI_DELIVERY.md HANDOFF.md TOKEN_ECONOMY.md
├── STATE.schema.md
├── nodes/   templates/   adapters/
```
