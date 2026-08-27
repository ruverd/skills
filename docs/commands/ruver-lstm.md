# `/ruver-lstm`

Looks shit to me. Graph engineer on the **author** side of a review.

Ingest a PR / review / comment URL. Patch should-fix on the **same
branch**. Rebase conflicts. Reply, resolve threads, re-request.

Never opens a new PR. Draft stays draft.

Skill: [`plugins/ruver/skills/ruver-lstm`](../../plugins/ruver/skills/ruver-lstm).

## When

- `/ruver-lstm https://github.com/org/repo/pull/99`
- `/ruver-lstm <review or comment URL>`
- `/ruver-lstm resume`
- Envelope: `LSTM_REQUEST`
- GitHub `CHANGES_REQUESTED` on a PR you own

## Graph

```
URL | resume | LSTM_REQUEST
  → admit
  → resolve comments
  → rebase if DIRTY / CONFLICTING
  → verify (receiving-code-review)
  → patch should-fix (ruver-fd-coder, TDD)
  → 👍 + reply + resolve threads + re-request
```

## What the main thread does

1. Resolve the PR and the comment ids.
2. Always rebase if GitHub says dirty/conflicting.
3. Verify each thread: fix / skip / unclear.
4. Complicated should-fix → grill first. Else `ruver-fd-coder` (TDD).
5. React 👍, reply, resolve, re-request review.

The graph engineer does not type the patch. The coder worker does.

Needs `receiving-code-review` and `unslop` if those skills are
installed.

## Never

- New PR.
- Merge.
- Spawn `/ruver-developer` or `/ruver-reviewer`.
- Skip rebase when the branch is conflicting.

## Related

[`/ruver-reviewer`](ruver-reviewer.md) · [`/ruver-developer`](ruver-developer.md)
