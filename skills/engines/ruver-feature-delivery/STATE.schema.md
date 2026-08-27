# STATE schema v4

**Path:** `$RUVER_ROOT/.ruver-feature-delivery/STATE.md`

## status

```
init | mcp | triage | grilling | waiting_user | speccing | ticketing |
diagnosing | implementing | reviewing | testing | blasting | quality |
shipping | ci_watching | waiting_blocker | handed_off | done | done_local |
done_report | escalated
```

- `waiting_user` — last-resort ASK in flight. Next message is the answer.
- `waiting_blocker` — external blocker open. Terminal for this session.
- `handed_off` — other runtime owns the run.
- `done` — PR + CI green. `done_local` — `--no-pr`. `done_report` — spike.

## mcp_gate

`pending | passed | passed_partial | failed`

## Fields

| Field | Use |
|---|---|
| `schema_version: 4` | resume compat |
| `path` | full_feature \| debug_fix \| light_change |
| `scope` | frontend_only \| backend_only \| fullstack |
| `spec_path` | `$RUVER_ROOT/.ruver-feature-delivery/SPEC.md` |
| `tickets_path` | `$RUVER_ROOT/.ruver-feature-delivery/TICKETS.md` |
| `current_ticket` | |
| `seams` | confirmed in spec/tickets |
| `linear_id` | |
| `pr_url` / `sha` | |
| `review_fix_loops` / `test_fix_loops` / `ci_fix_loops` | remaining + `*_used` |

## Whitelist per node

| Node | Reads | Writes |
|---|---|---|
| mcp_context | goal, refs | mcp_gate, linear_*, branch |
| triage | goal, linear-context | work_kind, scope, path, route_* |
| grill | goal, repo, Linear | decisions, approaches, `waiting_user` |
| spec | decisions | SPEC.md, spec_path |
| tickets | SPEC.md | TICKETS.md, seams, tickets_path |
| diagnose | sentry/linear, repo | debug (root cause, evidence, one ticket) |
| implement | one ticket + spec excerpt | code, tdd evidence, files_touched |
| review | spec, ticket, diff, gates.log | review |
| tester | files, scripts | hard gate + gates.log |
| blast | diff | blast section |
| quality | diff, files | quality section |
| shipper | gates | ship, ci.status=pending |
| ci_watch | pr_url | ci.status |
| blocker_handler | blockers | blockers[], waiting_blocker |
| fullstack | scope, branch | worktrees, run_id, prs |
| handoff | full | handed_off |
| orchestrator | full | status, run_log |

Orchestrator owns `status` transitions. Nodes report `result`.

## Rules

- Decision log required before spec/tickets.
- `tdd: required` — reviewer/shipper refuse without evidence on behavior change.
- Exit codes in `.ruver-feature-delivery/gates.log`. Cite them. Do not retype from memory.
- No secrets in STATE.
