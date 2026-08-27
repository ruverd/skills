# Token economy (ruver-fd)

Goal: **less repeated context**, **short prompts**, **artifacts on disk**
instead of pasting megabytes into chat. Quality does not drop. Budget stays
for the end (CI green / handoff).

## Principles

| Do | Avoid |
|---|---|
| STATE + files under `.ruver-feature-delivery/` as memory | Re-pasting the whole linear-context into every subagent |
| Whitelist per node (this ticket + refs) | "Read the whole monorepo" |
| Paths + 20–40 line excerpts | Dumping whole files into the prompt |
| Fresh subagent **with a minimal prompt** | Passing the session history to the subagent |
| 1 parallel tool call when independent | Re-read loops on the same file |
| User chat: short Brazilian Portuguese (status + next step) | Narrating every tool call |
| Incremental commits | Loading a 50-file diff into the orchestrator |

## By phase

### mcp_context
- Fetch MCP → **write to a file**; in chat only: ids, counts, `mcp_gate`.
- Do not reprint the full description in the orchestrator.

### triage / grill / spec
- Read the **summary** of linear-context (AC bullets), not the raw 10k tokens again if it is already on disk.
- Grill is the expensive model. Spec/tickets are synthesis, not a second interview.
- Coder prompt = this ticket + decisions + whitelist. Not the grill transcript.

### implement (subagents)
Coder prompt **at most ~1–2 screens**:

```
ticket N: <text>
done criteria: <bullets>
UI refs: path1, path2
contract: path or 15 lines
TDD: red→green
Do NOT read all of SPEC/TICKETS if the ticket text is already in the prompt
```

- Reviewer: `git diff` + files_touched + done criteria of the ticket.
- One ticket per subagent. Do not "resume" with a monster transcript.
- `how` / `why` only on the subsystem you will touch.

### quality / CI
- Logs: only the **tail** of the failure (`gh run view --log-failed`, filtered).
- Do not paste a full typecheck if the error is five lines.
- **Declared exception:** the quality node MAY load the touched files in full.
  It is the only node with that license (structural audit needs the whole file).
  Branch diff only, never "the monorepo".

### fullstack / Orca
- Worker spec: compact HANDOFF + paths to context files **in the worktree**, not a paste.

## User-facing compression

Unslop. [VOICE.md](VOICE.md). Preferred format (spoken in Brazilian Portuguese):

```text
S: phase + branch + mcp_gate
D: what changed (1–3 bullets)
P: next step / blocker / PR+CI
```

No preamble "I will now…".

## Orchestrator: anti-waste

1. **Do not** re-run MCP if `mcp_gate: passed` and context files exist (resume).
2. **Do not** re-triage if path/scope is already in STATE (unless the goal changed).
3. Before a limit handoff: **stop expanding scope**; close the current phase + write HANDOFF.
4. Prefer targeted `grep`/`codegraph` over `read` of 1k+ line files.

## Do not cut

- TDD evidence (paths + command + pass/fail)
- MCP gate errors
- Contract in the blocker comment
- CI check names + links when red
