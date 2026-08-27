---
name: ruver-lstm
description: >
  Graph: Looks shit to me. Author-side of review. Ingest a PR / review /
  inline thread / issue-comment URL, verify with receiving-code-review,
  patch should-fix on the same branch, always rebase merge conflicts,
  then 👍 + reply + resolve threads + re-request. Use when /ruver-lstm,
  /ruver_lstm, CHANGES_REQUESTED, review comments, or LSTM_REQUEST.
argument-hint: "<PR | review | comment URL> [--force]"
---

# Ruver LSTM (graph)

Looks shit to me. Orchestrator for **incoming** review, not `/ruver-reviewer`.

Never merge. Same PR. Same branch. Draft stays draft. No new PR.

**REQUIRED:** [GRAPH.md](GRAPH.md) · [ARGS.md](ARGS.md) ·
[STATE.schema.md](STATE.schema.md) ·
[HOST.md](../../HOST.md) ·
`receiving-code-review` ·
`unslop` ·
[GITHUB.md](references/GITHUB.md) ·
bus [PROTOCOL.md](../ruver-bus/PROTOCOL.md) ·
[DISK.md](../ruver-bus/DISK.md) ·
fd [DECISION_POLICY.md](../ruver-feature-delivery/DECISION_POLICY.md)

Init `.ruver-lstm/STATE.md`. Walk GRAPH (**admit** first).
Busy main or 2+ PRs → worktree + `general-purpose` worker per PR.

Orchestrator does **not** write product code. **patch** spawns
`ruver-fd-coder` (TDD). Grill only when the fix is complicated.
ASK last resort: [DECISION_POLICY.md](../ruver-feature-delivery/DECISION_POLICY.md).

User-facing chat in Brazilian Portuguese. Unslop.
Do not spawn `ruver_developer` / `ruver_reviewer` / `ruver_qa`.
