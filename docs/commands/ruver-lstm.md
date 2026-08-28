# `/ruver-lstm`

Alias: **`/lstm`**. Looks shit to me. Graph engineer on the **author**
side of a review.

Ingest a PR / review / comment URL. Patch should-fix on the **same
branch**. Rebase conflicts. 👍 + unslopped reply on every comment,
resolve threads, dismiss `CHANGES_REQUESTED`, re-request.

Never opens a new PR. Draft stays draft.

Skill: [`../../skills/ruver-lstm`](../../skills/ruver-lstm).

## When

- `/lstm https://github.com/org/repo/pull/99`
- `/lstm <review or comment URL>`
- `/lstm resume`
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
  → 👍 + unslopped reply on every comment
  → resolve threads + dismiss CHANGES_REQUESTED + re-request
```

## What the main thread does

1. Resolve the PR and the comment ids.
2. Always rebase if GitHub says dirty/conflicting.
3. Verify each thread: fix / skip / unclear.
4. Complicated should-fix → grill first. Else `ruver-fd-coder` (TDD).
5. 👍 + unslopped reply on **every** comment (fix and skip). Then
   resolve, dismiss `CHANGES_REQUESTED`, re-request if a fix landed.

The graph engineer does not type the patch. The coder worker does.

Uses bundled `receiving-code-review` and `unslop` (`skills/lib/`).

## Never

- New PR.
- Merge.
- Spawn `/ruver-developer` or `/ruver-reviewer`.
- Skip rebase when the branch is conflicting.
- Leave a comment without 👍 + reply.
- POST a GitHub reply that skipped `unslop`.
- Leave `CHANGES_REQUESTED` on a processed review.

## Related

[`/ruver-reviewer`](ruver-reviewer.md) · [`/ruver-developer`](ruver-developer.md)
