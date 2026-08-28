---
name: ruver-lstm
description: >
  Graph: Looks shit to me. Author-side of review. Ingest a PR / review /
  inline thread / issue-comment URL, verify with receiving-code-review,
  patch should-fix on the same branch, always rebase merge conflicts,
  then 👍 + unslopped reply on every comment, resolve threads,
  dismiss CHANGES_REQUESTED, re-request. Use when /lstm,
  /ruver-lstm, /ruver_lstm, CHANGES_REQUESTED, review comments, or
  LSTM_REQUEST.
argument-hint: "<PR | review | comment URL> [--force]"
---

# Ruver LSTM (graph)

Looks shit to me. Orchestrator for **incoming** review, not `/ruver-reviewer`.

Never merge. Same PR. Same branch. Draft stays draft. No new PR.

**REQUIRED:** [GRAPH.md](GRAPH.md) · [ARGS.md](ARGS.md) ·
[STATE.schema.md](STATE.schema.md) ·
[HOST.md](../../../HOST.md) ·
`receiving-code-review` ·
`unslop` ·
[GITHUB.md](references/GITHUB.md) ·
bus [PROTOCOL.md](../ruver-bus/PROTOCOL.md) ·
[DISK.md](../ruver-bus/DISK.md) ·
fd [DECISION_POLICY.md](../../engines/ruver-feature-delivery/DECISION_POLICY.md)

Init `.ruver-lstm/STATE.md`. Walk GRAPH (**admit** first).
Busy main or 2+ PRs → worktree + `general-purpose` worker per PR.

Orchestrator does **not** write product code. **patch** spawns
`ruver-fd-coder` (TDD). Grill only when the fix is complicated.
ASK last resort: [DECISION_POLICY.md](../../engines/ruver-feature-delivery/DECISION_POLICY.md).

User-facing chat in English. Unslop always. Every GitHub reply
(thread, skip reason, COMMENT review, dismiss message) is rewritten
with bundled `unslop` before POST. Never POST the first draft.

Reply is not optional. Every analyzed comment gets 👍 and a thread
reply. Then dismiss `CHANGES_REQUESTED`. Then re-request if a fix
landed. See [reply.md](nodes/reply.md).

Do not spawn `ruver_developer` / `ruver_reviewer` / `ruver_qa`.
