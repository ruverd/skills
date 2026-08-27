# `/ruver-goal`

Keeps delivery alive **across turns**. CI is often longer than a tool
timeout. This graph `schedule_wake`s until QA has commented **with
video** on the head SHA.

Skill: [`plugins/ruver/skills/ruver-goal`](../../plugins/ruver/skills/ruver-goal).

## When

- `/ruver-goal DEV-1212`
- `/ruver-goal https://github.com/org/repo/pull/99`
- `/ruver-goal status`
- `/ruver-goal cancel`
- After a draft PR exists and CI is still pending

## Completion bar

All must hold on the **current** head SHA:

1. Draft PR exists
2. Required CI green
3. MERGEABLE
4. QA comment with `ruver-qa` marker for that SHA
5. That comment has a **Video:** `https://` URL

See [COMPLETE.md](../../plugins/ruver/skills/ruver-goal/references/COMPLETE.md).

## Each wake

One step, then stop:

| World | Next |
|---|---|
| No PR | [developer](ruver-developer.md) `deliver` |
| CI pending | wait |
| CI red | developer `fix` |
| Green, not MERGEABLE | developer `mergeable` |
| Green + MERGEABLE, no QA on this SHA | enqueue-or-start [QA](ruver-qa.md) |
| QA FAIL + PR_BUG | developer `fix` |
| QA comment on this SHA (PASS / other) | **complete**, `cancel_wake` |

Wake primitive: [HOST.md](../../plugins/ruver/HOST.md) `schedule_wake`
(Grok `/loop`, otherwise ask the user to re-run).

## Never

- Claim done without the QA comment + video on **head** SHA
- `gh pr checks --watch`
- Spawn graph agents as children
- A second QA while `qa_active` is another PR
- Merge

## Related

[`/ruver-developer`](ruver-developer.md) · [`/ruver-qa`](ruver-qa.md)
