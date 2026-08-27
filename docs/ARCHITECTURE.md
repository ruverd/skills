# Ruver architecture

Command pages: [commands/](commands/README.md).

Five graphs share one session. They do not nest. They pass work through
files on the bus.

```
developer ⇄ qa ⇄ triage
     ⇄ reviewer
     ⇄ lstm
```

The **main thread** is the only graph runner. Outbound work writes an
envelope under `$RUVER_ROOT/.ruver-bus/`, pushes the stack, and loads
the target graph. Graphs never `spawn_worker` another graph
(`load_graph` on this thread). See [GRAPH_ENGINEER.md](GRAPH_ENGINEER.md)
and [HOST.md](../HOST.md).

Worker subagents (`ruver-fd-coder`, `ruver-fd-tester`, …) implement
product code. They are not graphs.

## Disk

```bash
slug=$(git rev-parse --show-toplevel | sed 's|^/||; s|/|-|g')
RUVER_ROOT="${RUVER_HOME:-$HOME/.ruver}/$slug"
```

Every `.ruver-*` directory lives under `$RUVER_ROOT`. See
`../skills/graphs/ruver-bus/DISK.md`.

## /ruver-developer

```
goal | Linear id | resume | QA_RESULT FAIL+PR_BUG
        │
     admit
        │
   ┌────┴─────┐
   ▼          ▼
deliver      fix
 (fd)    (same PR)
   │          │
   └────┬─────┘
        ▼
    mergeable          CI green AND mergeable
        │
   request_qa  ──bus──►  /ruver-qa
        │
   apply_qa
        │
   PASS → gh pr ready
   FAIL+PR_BUG → fix
```

Delivery spine inside `ruver-feature-delivery`:

```
grill-with-docs → spec → tickets → implement (TDD) → review → CI
```

Bugs go through diagnose first. The orchestrator does not write product
code. `ruver-fd-coder` does, one ticket at a time.

## /ruver-qa

```
PR from args or QA_REQUEST
  → admit          one slot; else enqueue
  → plan           from the diff, before any click
  → execute        Playwright + browser, record video
  → triage?        product suspicion → bus → /ruver-triage
  → verdict        comment + video + QA_RESULT
```

Backend-only PRs still map to the frontend route that calls the API.
Unit tests or `git show` are not a complete execute.

## /ruver-lstm

Looks shit to me. Author side of review. Same PR, same branch.

```
URL | resume | LSTM_REQUEST
  → admit
  → resolve comments
  → rebase if DIRTY / CONFLICTING
  → verify (receiving-code-review)
  → patch should-fix (ruver-fd-coder, TDD)
  → 👍 + reply + resolve threads + re-request
```

Never opens a new PR. Draft stays draft.

## Reviewer vs LSTM vs code-review

| Name | Who | Job |
|---|---|---|
| `/ruver-reviewer` | reviewer | Run `/ruver-code-review`, report. |
| `/ruver-code-review` | engine | Deep/light review, one artifact per PR. |
| `/ruver-lstm` | author | Consume that review and patch. |

## Goal loop

`/ruver-goal` uses `schedule_wake` (HOST.md) until the draft PR is
CI-green, MERGEABLE, and has a QA comment with video on the head SHA.
CI is often longer than a tool timeout, so the loop polls instead of
`gh pr checks --watch`.

## Invariants

- Never merge. `gh pr ready` only after QA PASS.
- Chat with the user in Brazilian Portuguese. Skill files stay English.
- ASK the user only as a last resort.
- Unslop.
