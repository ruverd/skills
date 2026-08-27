# CI / QA wake loop

Use Grok **`scheduler_create`** (same as `/loop`). Do not block the
turn on `gh pr checks --watch`.

## Create (once per PR)

If STATE already has `loop_id`, do not create a second loop.

```
scheduler_create
  interval: "5m"
  fire_immediately: false
  durable: false
  prompt: <exact text below>
```

Store the returned `task_id` in `.ruver-goal/STATE.md` as `loop_id`.

## Prompt (paste verbatim, fill PR/repo)

```text
Continue ruver-goal. Load ~/.agents/skills/ruver-goal/SKILL.md.

PR: <url>
Repo: <owner/repo>
Goal state: .ruver-goal/STATE.md

Inspect gh (pr view, pr checks, issue comments) for this PR.
Take exactly one next step from the ruver-goal table (wait / fix /
mergeable / enqueue-or-start QA via ruver-bus/JOBS.md / complete).
Never start a second QA if qa_active is another PR.
If CI is still pending, do nothing else and end the turn.
If a ruver-qa marker comment exists for the current head SHA and
includes a video URL, delete this loop (scheduler_delete) and stop.
Do not merge. Chat PT-BR, one short S/D/P block.
```

Interval **5m** (empath-ui CI is 20–30 min). Min 60s.

## Delete

`scheduler_delete` with `loop_id` when:

- COMPLETE.md is satisfied, or
- user runs `/ruver-goal cancel`, or
- PR is closed/merged (still never merge ourselves).

If delete fails, report the id; do not leave a silent loop.
