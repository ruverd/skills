# Node: mcp_context

**Verb:** gather + **verify**
**Capability:** MCP read + git branch if Linear
**When:** **always** at the start; **before** any implement

## Mission

1. Verify MCP access for the needed sources.
2. Load real context.
3. If a critical source fails → **explicit error in Brazilian Portuguese** and `blocked` — **no inventing**.

[MCP_CONTEXT.md](../MCP_CONTEXT.md) · [LINEAR.md](../LINEAR.md)

## Steps

1. Scan the goal for IDs/URLs.
2. For each source (Linear, Figma, Sentry, Notion, …):
   - **Pre-check:** is the MCP server available in the session?
   - If **critical** and unreachable → build the **ERROR: MCP unreachable** block (template in MCP_CONTEXT.md), write STATE `mcp_gate: failed`, **return blocked**.
   - If ok → full fetch → `*-context.md`.
3. Linear ok → checkout branch.
4. Re-scan Linear body for links → more fetches.
5. `mcp-sources.md` + STATE.

## Output

```text
result: ok | partial | blocked | skipped
mcp_gate: passed | failed
error_pt: ...   # required if blocked by MCP; speak in Brazilian Portuguese
linear_id / linear_branch / sources map
```

## Runtime note

If the runtime does not expose MCP to subagents (e.g. Claude Code with tool search —
BASELINE smoke S1), this node runs **on the main thread** (orchestrator executes the steps).
Gather/write of context is not product code — it does not violate the orchestrator rule.

## Hard rules

- **Never** invent content from an offline MCP.
- **Never** implement if `mcp_gate: failed` or `result: blocked` for a critical source.
- Error in Brazilian Portuguese, clear, with source + server + ref + how to unblock.
- Zero product code in this node.
