# Developer graph

```
              start  (ARGS.md: goal | ticket | resume | fix)
                │
        ┌───────┴────────┐
        ▼                ▼
     resume            admit
   (STATE on disk)        │
        │          ┌──────┴────────┐
        │          ▼               ▼
        │     goal / ticket   QA_RESULT FAIL+PR_BUG
        │          │               │
        └────┬─────┘               │
             ▼                     ▼
          deliver                 fix
     (ruver-feature-delivery) (existing PR)
        │                │
        └───────┬────────┘
                ▼
            mergeable
                │
           ok   │   not MERGEABLE
                │        │
                ▼        ▼
           request_qa   resolve branch / escalate
                │
      enqueue-or-start QA
                │
           QA_RESULT
                │
        ┌───────┼────────────┐
        ▼       ▼            ▼
      PASS   FAIL+PR_BUG   other
        │       │            │
   ready+done  fix ──┘    done_notes / escalate
```

## Edges

| From | Condition | To |
|---|---|---|
| start | `resume` / same Linear id or goal slug with live STATE | **resume** (reconcile, continue) |
| start | goal text, or Linear id / URL, no live STATE | **admit** |
| start | `QA_RESULT` FAIL + `PR_BUG` | **admit** then **fix** |
| start | empty args and live STATE | **resume** |
| start | no args, no STATE, no goal | **stop** (ask for the ticket or the goal) |
| admit | idle main | **deliver** or **fix** |
| admit | busy main | worker + worktree; **stop** this call |
| resume | delivery not done | **deliver** (skip finished nodes) |
| resume | delivery done | **mergeable** or **apply_qa** as STATE says |
| deliver | fd `status=done` (CI green) | **mergeable** |
| deliver | escalated / waiting_user / handed_off / waiting_blocker | **stop** |
| fix | pushed to same PR | **mergeable** |
| mergeable | MERGEABLE + CI green | **request_qa** |
| mergeable | conflict / dirty | fix branch → mergeable |
| request_qa | QA slot free | **bus → qa** |
| request_qa | QA slot taken | enqueue; stay on developer |
| apply_qa | `QA_RESULT` PASS | **ready** (`gh pr ready`) then **done** |
| apply_qa | FAIL and triage `PR_BUG` | **fix** |
| apply_qa | NEW_BUG / EXISTING_BUG / NOT_A_BUG | **ready** + **done** (notes) |
| apply_qa | `PENDING_TRIAGE` | **wait** |
| apply_qa | BLOCKED | **escalate** |

## Node files

`nodes/resume.md` · `nodes/admit.md` · `nodes/deliver.md` · `nodes/fix.md` ·
`nodes/mergeable.md` · `nodes/request_qa.md` · `nodes/apply_qa.md`

## Defaults

```yaml
never_merge: true
stay_draft: until_qa_pass
open_pr: true
reuse_fd_graph: true
chat_language: en  # default; ruver-memory overrides. This file is English.
voice: unslop
decide_by_default: true
ask_last_resort_only: true
```
