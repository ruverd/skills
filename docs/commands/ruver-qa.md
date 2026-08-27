# `/ruver-qa`

Graph engineer for **product QA**. One Playwright/browser slot.
Plan from the diff before any click. Comment with video.

Skill: [`../../skills/graphs/ruver-qa`](../../skills/graphs/ruver-qa).

## When

- `/ruver-qa https://github.com/org/repo/pull/99`
- `/ruver-qa owner/repo#99`
- Envelope: `QA_REQUEST` from [developer](ruver-developer.md)

## Graph

```
PR from args or QA_REQUEST
  → admit          one slot; else enqueue
  → plan           from the diff, before any click
  → execute        browser + Playwright, record video
  → triage?        product suspicion → bus → /ruver-triage
  → verdict        comment + video + QA_RESULT
```

## What “done” means

A GitHub PR comment on the **head SHA** with a video URL. Chat-only
is not done. Unit tests or `git show` are not a complete execute.

Backend-only PRs still map to the **frontend route** that calls the
API, hit that screen, and record it.

## Slot

Never two executes. If another PR holds `qa_active`, this one
**enqueues** ([ruver-bus JOBS](../../skills/graphs/ruver-bus/JOBS.md)).

The graph engineer does **not** classify bugs. Suspicion →
[`/ruver-triage`](ruver-triage.md). After `TRIAGE_RESULT`, continue at
**verdict** (do not re-run execute).

## Never

- Spawn `ruver_triage` as a child.
- Skip the PR comment.
- `gh gist create` on `.webm` (use `scripts/publish-evidence.sh`).
- PASS without a video of the FE route.

## Related

[`/ruver-triage`](ruver-triage.md) · [`/ruver-developer`](ruver-developer.md) ·
[`/ruver-goal`](ruver-goal.md)
