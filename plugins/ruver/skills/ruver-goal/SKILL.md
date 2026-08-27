---
name: ruver-goal
description: >
  Drive developer → CI green → QA comment+video with Grok /goal and
  /loop so the circuit continues across turns. Use when the user runs
  /ruver-goal or /ruver_goal, says "usa o goal/loop", or after a draft
  PR is opened and CI is still pending.
argument-hint: "<DEV-XXXX | PR url | status | cancel>"
---

# Ruver goal / loop

The graphs do **not** finish in one turn. CI takes 20–30 min. This
skill keeps the session working until QA has **commented with video**.

**REQUIRED:** [COMPLETE.md](references/COMPLETE.md) ·
[LOOP.md](references/LOOP.md) · bus PROTOCOL.md ·
[DISK.md](../ruver-bus/DISK.md) (`.ruver-*` is **global**, never git root)

Chat PT-BR.

## Commands

| Args | Action |
|---|---|
| `DEV-XXXX` / feature text | Start goal + developer graph |
| PR url / `owner/repo#N` | Start goal on that PR (skip implement if it exists) |
| `status` | Read `.ruver-goal/STATE.md` + `gh pr checks` + last QA comment |
| `cancel` | Delete the scheduler loop; leave graphs as-is |

## Start

1. Write `.ruver-goal/STATE.md` from
   [templates/STATE.md](templates/STATE.md).
2. Tell the user to run this **host** goal (verifier needs it):

```text
/goal Draft PR for <id> is CI-green, MERGEABLE, and has a ruver-qa
comment on the head SHA that includes a video URL.
```

3. If there is no PR yet → load **ruver-developer** GRAPH (`deliver`).
4. When a draft PR exists and CI is not green → **start the loop**
   ([LOOP.md](references/LOOP.md)). Do not `gh pr checks --watch`.
5. Stop the turn. The loop wakes the session.

## Each `/loop` fire (or `/ruver-goal` resume)

Read STATE. Inspect the real PR (`gh pr view`, `gh pr checks`,
issue comments). Then **one** step:

| World | Next |
|---|---|
| No PR | developer `deliver` |
| CI pending / in progress | stop (wait for next fire) |
| CI red | developer `fix` / fd ci loop |
| Green but not MERGEABLE | developer `mergeable` |
| Green + MERGEABLE, no QA comment on **this** SHA | enqueue-or-start QA (JOBS.md) |
| QA comment on this SHA, verdict FAIL + PR_BUG | developer `fix` |
| QA comment on this SHA, PASS / FAIL-unrelated / BLOCKED documented | **complete** |

Complete = [COMPLETE.md](references/COMPLETE.md) all true, then
`scheduler_delete` the loop.

## Never

- Claim the goal done without the QA comment + video on **head** SHA
- Sit in `--watch` (tool timeout < empath-ui CI)
- Spawn graph-agents as children (bus switch / load GRAPH)
- Start a second QA while `qa_active` is another PR
- Merge

## After QA comment

Cancel the loop. Report PT-BR: PR, SHA, QA verdict, comment URL, video URL.
