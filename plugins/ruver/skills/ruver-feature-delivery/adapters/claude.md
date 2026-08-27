# Adapter: Claude Code

## Install layout (global)

```
~/.agents/skills/ruver-feature-delivery/     # source of truth
~/.claude/skills/ruver-feature-delivery  →   # symlink
~/.claude/agents/ruver-fd-*.md               # specialist agents
~/.claude/commands/ruver-feature-delivery.md # /ruver-feature-delivery
~/.claude/commands/ruver-fd.md               # alias
```

## How to run

In any repo:

```text
/ruver-fd <goal>              # draft PR at the end (default)
/ruver-fd <goal> --no-pr      # no PR
```

Speak to the user in Brazilian Portuguese.

## Orchestrator behavior (main session)

1. Load skill + TOKEN_ECONOMY + HANDOFF + MCP + rest.
2. If **resume**: HANDOFF → **RECONCILE** (git/gh vs STATE) → Next steps
   (skip only what was verified).
3. Main **does not** implement product code; keep prompts short.
4. MCP gate → triage → path/scope. Grill/spec/tickets on the **main thread**. Then implement/fullstack/blocker.
5. review → tester → blast (not light) → quality (thermo) → shipper → **ci** until green = delivered.
6. **Limit near:** write HANDOFF; user continues on **Grok** (or
   vice versa) with `/ruver-fd resume`.
7. Short Brazilian Portuguese chat; never merge.

## Agent mapping

| Node | Agent |
|---|---|
| mcp_context | `ruver-fd-context` |
| triage | `ruver-fd-triage` |
| fullstack | `ruver-fd-fullstack` |
| blocker | `ruver-fd-blocker` |
| diagnose | `ruver-fd-debugger` (legacy name) |
| grill / spec / tickets | **main thread** (do not spawn brainstormer/planner) |
| implement | `ruver-fd-coder` (fresh / ticket) |
| blast | **main thread** (pstack blast-radius) |
| reviewer | `ruver-fd-reviewer` (fresh) |
| tester | `ruver-fd-tester` |
| quality | `ruver-fd-quality` |
| shipper | `ruver-fd-shipper` |
| ci_watch | `ruver-fd-ci` (dispatches `ruver-fd-coder` for fixes via `Agent(ruver-fd-coder)`) |

### Tool/model rules (from the 2026-08-08 audit)

- `ruver-fd-context` and `ruver-fd-blocker` **have no** `tools:` line (an explicit
  allowlist EXCLUDES MCP). However — **verified in 2026-08-08 smoke**: with
  `ENABLE_TOOL_SEARCH=true` (this setup), custom subagents do NOT receive MCP tools
  and cannot load them via tool search.
- **Operating rule:** MCP steps of mcp_context and blocker run on the
  **MAIN THREAD** (orchestrator executes `nodes/mcp_context.md` / BLOCKERS.md MCP
  steps itself — gather/write of context, not product code).
  Agents `ruver-fd-context`/`ruver-fd-blocker` only enter if BASELINE smoke S1
  passes in that environment.
- A subagent without MCP returns `result: mcp_unavailable_in_subagent` — that is NOT
  `mcp_gate: failed` (the source may still be reachable to the orchestrator).
- `model:` pins in agent files are the default; the orchestrator scales with the
  Agent tool `model` parameter (multi-file coder / final reviewer → frontier).
- Smoke test after editing any agent: dispatch with a trivial prompt and confirm
  each mission-critical tool resolves (e.g. context → read-only `get_issue`).

## Manual autonomy (v1)

- User starts the graph.
- No background routine required.
- Stop at human for merge.
- `open_pr` **defaults true** (draft PR). Only `false` with `--no-pr` / "no PR".

## Resume

Re-run `/ruver-feature-delivery` (or "resume feature delivery") in the same repo.
Orchestrator reads STATE.status and continues from the matching edge.
