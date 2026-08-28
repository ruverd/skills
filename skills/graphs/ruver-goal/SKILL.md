---
name: ruver-goal
category: graph
description: >
  Drive developer → CI green → QA comment+evidence across turns with
  schedule_wake (HOST.md). Use when /ruver-goal, /ruver_goal, or after
  a draft PR is opened and CI is still pending.
argument-hint: "<ticket | PR url | status | cancel>"
---

# Ruver goal / loop

The graphs do **not** finish in one turn. CI takes 20–30 min. This
skill keeps the session working until QA has **commented with evidence**.

**REQUIRED:** [COMPLETE.md](references/COMPLETE.md) ·
[LOOP.md](references/LOOP.md) · bus PROTOCOL.md ·
[DISK.md](../ruver-bus/DISK.md) (`.ruver-*` is **global**, never git root) ·
`ruver-memory`

Chat: `ruver-memory`. Unslop always.

## Commands

| Args | Action |
|---|---|
| ticket id / feature text | Start goal + developer graph |
| PR url / `owner/repo#N` | Start goal on that PR (skip implement if it exists) |
| `status` | Read `.ruver-goal/STATE.md` + `gh pr checks` + last QA comment |
| `cancel` | Delete the scheduler loop; leave graphs as-is |

## Start

1. Load `ruver-memory`. Write `.ruver-goal/STATE.md` from
   [templates/STATE.md](templates/STATE.md).
2. Name the completion bar (verifier / user):

```text
Draft PR for <id> is CI-green, MERGEABLE, and has a ruver-qa
comment on the head SHA that includes evidence.
```

If the host has a `/goal` (or equivalent) command, register that
sentence there. If it does not, STATE is enough.

3. If there is no PR yet → load **ruver-developer** GRAPH (`deliver`).
4. When a draft PR exists and CI is not green → **schedule_wake**
   ([LOOP.md](references/LOOP.md)). Do not `gh pr checks --watch`.
5. Stop the turn. The wake resumes this skill.

## Each wake (or `/ruver-goal` resume)

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
`cancel_wake`.

## Never

- Claim the goal done without the QA comment + evidence on **head** SHA
- Sit in `--watch` (CI is longer than a tool timeout)
- Spawn graph-agents as children (bus switch / load GRAPH)
- Start a second QA while `qa_active` is another PR
- Merge

## After QA comment

Cancel the loop. Report in the chat language: PR, SHA, QA verdict, comment URL, evidence URL.
