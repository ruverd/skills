# QA graph

```
start (PR from args or QA_REQUEST)
  → admit            # one QA slot; else enqueue and stop
  → resolve
  → plan             # inventory + step-by-step from the diff
  → execute          # walk PLAN.md; append FINDINGS as they appear
  → gate
       ├ no findings / unambiguous FAIL → verdict
       └ any product suspicion          → request_triage
                                              │
                                       bus → triage
                                              │
                                       TRIAGE_RESULT
                                              │
                                           verdict
                                              │
                              QA_RESULT + pop + dequeue
```

## Edges

| From | Condition | To |
|---|---|---|
| start | no PR | **stop** (ask) |
| start | PR present | **admit** |
| admit | `qa_active` other PR | **enqueue** and **stop** |
| admit | slot free or this job | **resolve** |
| resolve | ok | **plan** |
| plan | PLAN.md has ≥1 step | **execute** |
| plan | no surface | **stop** (ask) |
| execute | plan finished, no findings | **verdict** (`PASS` or infra `BLOCKED`) |
| execute | plan finished, findings exist | **request_triage** |
| execute | unambiguous FAIL (VERDICTS.md) | **verdict** `FAIL` |
| execute | cannot run (env/auth/app) | **verdict** `BLOCKED` |
| request_triage | envelope written | **bus → triage** |
| verdict | after execute or TRIAGE_RESULT | comment + `QA_RESULT` + pop + apply_qa + **dequeue** |

Unambiguous FAIL: [references/VERDICTS.md](references/VERDICTS.md).  
Plan how: [references/PLAN.md](references/PLAN.md).  
Handoff body: [references/HANDOFF.md](references/HANDOFF.md).  
Execute how: [references/EXECUTION.md](references/EXECUTION.md).

## Nodes

`nodes/admit.md` · `nodes/resolve.md` · `nodes/plan.md` ·
`nodes/execute.md` · `nodes/request_triage.md` · `nodes/verdict.md`

Queue: `~/.agents/skills/ruver-bus/JOBS.md`. Never two executes.
