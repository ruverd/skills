# CI / QA wake loop

`schedule_wake` ([ruver-host](../../ruver-host/SKILL.md)). Do not block the turn
on `gh pr checks --watch`.

## Create (once per PR)

If STATE already has `loop_id`, do not create a second loop.

```
schedule_wake
  interval: "5m"
  fire_immediately: false
  prompt: <exact text below>
```

Store the host's wake id in `.ruver-goal/STATE.md` as `loop_id`.

## Prompt (paste verbatim, fill PR/repo)

```text
Continue ruver-goal. load_skill ruver-goal.

PR: <url>
Repo: <owner/repo>
Goal state: .ruver-goal/STATE.md

Inspect gh (pr view, pr checks, issue comments) for this PR.
Take exactly one next step from the ruver-goal table (wait / fix /
mergeable / enqueue-or-start QA via ruver-bus/JOBS.md / complete).
Never start a second QA if qa_active is another PR.
If CI is still pending, do nothing else and end the turn.
If a ruver-qa marker comment exists for the current head SHA and
includes a video URL, cancel_wake and stop.
Do not merge. Chat: `ruver-memory`. Unslop always, one short S/D/P block.
```

Interval **5m**. Min 60s. CI that takes longer than a tool timeout
is why this loop exists.

## Delete

`cancel_wake` with `loop_id` when:

- COMPLETE.md is satisfied, or
- user runs `/ruver-goal cancel`, or
- PR is closed/merged (still never merge ourselves).

If delete fails, report the id; do not leave a silent loop.
