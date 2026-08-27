# Adapter: Grok

## Install layout (verified on disk)

```
~/.agents/skills/ruver-feature-delivery/       # source of truth (same as Claude)
~/.grok/skills/ruver-feature-delivery →        # symlink (Grok follows skill symlinks)
~/.grok/skills/ruver-fd →                      # symlink alias
~/.grok/workflows/ruver-feature-delivery.rhai  # workflow runner — partial coverage (see Runner)
```

## Invocation

- **`/ruver-fd` does not exist** as a Grok command — slash commands there are fixed
  built-ins. Use **`/skills ruver-feature-delivery`** (injects the skill) + state the
  goal, or rely on auto-invoke from the description.
- Resume: `/skills ruver-feature-delivery` + "resume" → **RECONCILE** first
  (HANDOFF.md), then Next steps.

## Runner (two forms, not equivalent today)

1. **Main-session orchestration (recommended):** the main session follows
   SKILL.md/GRAPH.md and dispatches one `agent()` per node, injecting the matching
   `nodes/<node>.md` as the prompt contract.
   No `parallel()` of coders — one `agent()` per unit of work.
2. **Workflow** (`~/.grok/workflows/ruver-feature-delivery.rhai`): same spine as
   GRAPH.md (grill → spec → tickets → TDD → review → tester → blast → thermo →
   ship → CI). Fresh single-repo only. Resume / ASK / fullstack / blockers /
   handoff-on-limit still stop and tell you to continue on the main session.

## Subagents / roles

Grok supports `[subagents.roles]` in `~/.grok/config.toml` (`prompt_file`,
`default_capability_mode`, `model`) — a natural mapping of the nodes. Snippet to
paste/adjust:

```toml
[subagents.roles.ruver-fd-reviewer]
description = "Ruver FD reviewer (read-only)"
default_capability_mode = "read-only"
prompt_file = "~/.agents/skills/ruver-feature-delivery/nodes/reviewer.md"

[subagents.roles.ruver-fd-coder]
description = "Ruver FD coder (TDD, one ticket at a time)"
default_capability_mode = "read-write"
prompt_file = "~/.agents/skills/ruver-feature-delivery/nodes/coder.md"
```

Without roles configured: inline the contract in the `agent()` prompt and use the session
model (IMPLEMENTATION.md model hints are Claude-only for now).

## MCP (status of this machine)

`~/.grok/config.toml` registers **Linear only**. Gate consequence: a ticket with
**critical** Figma/Sentry/Notion → STOP on Grok by design. Do not hand off
Claude→Grok in a phase that still needs those sources — or add the
`[mcp_servers.*]` to config.toml first.

## Autonomy

Grok runs `permission_mode = "always-approve"`: push, draft PR, and CI fixes
happen **without a human prompt**. The handoff message must tell the user that.

## debug_fix

Load pstack `diagnose` + `nodes/diagnose.md` **before** the coder. No Superpowers systematic-debugging.

## Spine

Grill stays on the main thread in a live session. Spec and tickets too. Do not spawn brainstormer/planner.

The named workflow follows the same GRAPH. ASK and resume still belong on the main session.

## ci_watch

No `loop-on-ci`/`fix-ci` skills on Grok: follow `nodes/ci_watch.md` +
`CI_DELIVERY.md`, with the STATE `ci_fix_loops` cap.
