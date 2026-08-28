# Jobs, workers, QA queue

**One home.** Developer, reviewer, lstm, and QA admit/enqueue here.
Do not copy this table into those SKILL.md files.

## Disk

Under `$RUVER_ROOT` ([DISK.md](DISK.md)). **Never** the git root.

```
.ruver-bus/
  JOBS.md                 # registry + qa_active / qa_waiting
  jobs/<id>/
    STATE.md              # worker / parked job (not the foreground)
    qa-request.md         # parked QA_REQUEST
    RESULT.md             # worker return
```

Init JOBS from [templates/JOBS.md](templates/JOBS.md) if missing.

## Job id

`dev-<TICKET|pr-N>` · `rev-pr-N` · `lstm-pr-N` · `qa-pr-N`

## Main is busy

Last line of `STACK.md` is `qa` or `triage`, **or** a
**foreground** developer/reviewer/lstm job is not terminal
(`done` / `done_notes` / `escalated`).

Idle: empty stack, or only terminal jobs.

## Interrupt (user / envelope while a graph runs)

| Incoming | Active main | Action |
|---|---|---|
| developer ticket / fix | busy | **worker + worktree**. Do not steal main. |
| reviewer | busy | **worker + worktree**. Do not steal main. |
| lstm | busy | **worker + worktree**. Do not steal main. |
| `QA_REQUEST` / `/ruver-qa` | other QA `qa_active` set | **enqueue**. Never start a second QA. |
| `QA_REQUEST` / `/ruver-qa` | no `qa_active` | start QA (claim `qa_active`). |
| developer / reviewer / lstm | QA or triage on main | worker + worktree. **Do not abort QA.** |

Never two `plan`/`execute` QA runs. Browser / e2e / HTTP QA
on this machine is **one slot**.

## Developer / reviewer / lstm — admit

1. Register the job on `JOBS.md`.
2. If main is **idle** for this call → `lane=foreground`.
   Write `.ruver-<kind>/STATE.md`. Continue the graph on main.
   No extra worktree unless already isolated.
3. If main is **busy** → `lane=worker`:
   - Create a worktree ([Worktree](#worktree)).
   - Spawn **one** `general-purpose` subagent ([Worker](#worker)).
   - Record `worktree`, `worker_id`. Chat (`ruver-memory`): job id + path.
   - **Do not** leave the graph that already owns main.

Foreground job keeps `.ruver-developer/STATE.md` (or reviewer / lstm).
Worker jobs use `.ruver-bus/jobs/<id>/STATE.md` only.

## Worktree

Prefer host `spawn_worker` with worktree isolation ([HOST.md](../../../HOST.md)).
Do not also pass `cwd` when isolation is a worktree.

Else git fallback (`.worktrees/` if the repo gitignores it, else a sibling dir):

```bash
git rev-parse --show-toplevel          # repo root
git check-ignore -q .worktrees
git worktree add ".worktrees/<id>" -b "<branch>" origin/main
```

Reuse the ticket branch if it already exists
(`feature/<id-lowercase>` or Linear `gitBranchName`).
Do not nest a worktree inside another worktree.
Do not run the full test suite as a baseline (too heavy). Install
deps with the discovered `pkg` only if they are missing in that worktree.

## Worker

Child type: general-purpose ([HOST.md](../../../HOST.md) `spawn_worker`).
**Never** spawn types `ruver_developer` / `ruver_qa` / `ruver_triage` /
`ruver_reviewer` / `ruver_lstm`.
Worker **must not** spawn children.

Prompt must include: job id, worktree path (or “host worktree”),
PR/ticket, “execute the skill **yourself** — no ruver-* / ruver-fd-*
spawns”, never merge, stay draft.

| kind | Worker does |
|---|---|
| developer | `ruver-feature-delivery` nodes inline (or Fix contract). Draft PR. Write `jobs/<id>/RESULT.md`. |
| reviewer | `ruver-code-review` for **one** PR only. Write `RESULT.md`. |
| lstm | `ruver-lstm` nodes inline for **one** PR. Same branch. TDD via coder contract (spawn `ruver-fd-coder` on foreground; inline on depth-1 worker). Write `RESULT.md`. |

On RESULT: update JOBS. Developer worker with green+MERGEABLE →
[Enqueue or start QA](#enqueue-or-start-qa). CI pending → start
`ruver-goal` loop for **that** PR (one loop per PR).

## Enqueue or start QA

Slot = `qa_active` empty.

1. Write `jobs/<id>/qa-request.md` (full `QA_REQUEST` body).
2. **Free:** `qa_active=<id>`. Copy to `ENVELOPE.md`. Bus switch
   to `qa`.
3. **Taken:** append `<id>` to `qa_waiting`. Do **not** switch.
   Do **not** touch `.ruver-qa/STATE.md`. Chat: queue position.

Triage stacked on QA still holds the slot (`qa_active` stays).

## After a QA verdict

1. Write `QA_RESULT`. Pop. Run developer `apply_qa` for that job
   **to completion** (do not skip).
2. Clear `qa_active`.
3. If `qa_waiting` is non-empty: dequeue head → `qa_active`,
   copy `jobs/<id>/qa-request.md` → `ENVELOPE.md`, push `qa`,
   load QA graph. Reset `.ruver-qa/STATE.md` from the template
   for the new PR.

Standalone `/ruver-qa` (no developer on stack): same dequeue
after verdict.

## Anti-patterns

- Two QA `execute` at once
- Aborting QA because a new ticket arrived
- Spawning a graph type as the worker
- Worker spawning fd coder / another graph
- Overwriting `.ruver-qa/STATE.md` for a queued PR
- `git worktree add` when `isolation: "worktree"` is available
