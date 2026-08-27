# Ruver feature delivery — graph

## Spine

Bundled primitives. Not Superpowers brainstorm / writing-plans / SDD.

```
goal / resume
  → mcp_context
  → triage
       ├ scope=fullstack → fullstack (Orca, same branch) then this path per worker
       ├ full_feature → grill → spec → tickets → implement* → review → tester
       ├ debug_fix    → diagnose → one ticket → implement → review → tester
       └ light_change → tickets (single) → implement → review → tester
  → (more tickets? implement next)
  → blast (skip on light_change)
  → quality (thermo fix all)
  → shipper → ci_watch
```

`implement*` is one fresh coder subagent **per ticket**. Verify the
ticket before starting the next (bundled
`principle-sequence-verifiable-units`).

Grill, spec, and tickets run on the **main thread**. Implement / review / diagnose / tester / quality / shipper / ci are nodes (subagents where the adapter says so).

## Edges

| From | Condition | To |
|---|---|---|
| start | resume with live STATE | current node (skip finished) |
| start | fresh goal / Linear | **mcp_context** |
| mcp_context | mcp_gate=passed / passed_partial | **triage** |
| mcp_context | mcp_gate=failed | **STOP** + PT-BR error |
| triage | scope=fullstack | **fullstack** (FULLSTACK.md) |
| triage | path=full_feature | **grill** |
| triage | path=debug_fix | **diagnose** |
| triage | path=light_change | **tickets** (single) |
| triage | path unclear | DECIDE the narrower path; ASK only last-resort policy |
| grill | frontier empty | **spec** |
| grill | ungrillable | prototype, then DECIDE or ASK |
| grill | ASK in flight | `waiting_user` **stop** |
| spec | SPEC.md written | **tickets** |
| tickets | tickets written, seams decided | **implement** (first unblocked ticket) |
| diagnose | root cause + fix slice | **implement** (one ticket) |
| diagnose | this is a feature | re-route **grill** |
| diagnose | ASK needed | `waiting_user` |
| implement | DONE | **review** |
| implement | NEEDS_CONTEXT / BLOCKED | ASK or escalate |
| review | fail + loops left | **implement** (same ticket) |
| review | fail + loops exhausted | **escalate** |
| review | pass | **tester** |
| tester | fail + loops left | **implement** |
| tester | fail + loops exhausted | **escalate** |
| tester | pass + more tickets | **implement** (next) |
| tester | pass + no more tickets + not light | **blast** |
| tester | pass + no more tickets + light_change | **quality** |
| blast | done | **quality** |
| quality | ok | **shipper** |
| quality | blocked | **escalate** |
| shipper | PR created | **ci_watch** |
| shipper | `--no-pr` | `done_local` |
| ci_watch | all green | **done** |
| ci_watch | fail + loops left | **implement** (fix) → push → ci_watch |
| ci_watch | loops exhausted | **escalate** |
| plan/implement | missing contract or open blocker | **blocker_handler** |
| blocker_handler | blocker Done | resume implement |
| blocker_handler | blocker open | `waiting_blocker` → **end session** |
| any | user must decide | `waiting_user` **stop** |
| any | context/limit | **handoff** |
| triage | work_kind=spike | diagnose read-only → `done_report` |

## Defaults

```yaml
open_pr: true
thermo_nuclear: required_when_shipping
ci_green_required: true
ci_fix_loops: 5
review_fix_loops: 2
test_fix_loops: 2
tdd: required_for_behavior_change
subagents_on_implement: always
never_merge: true
stay_draft: true
chat_language: pt-BR  # user-facing messages only; this file is English
decide_by_default: true
ask_last_resort_only: true
architect_checkpoint: last_resort_only
```

## Skills

See [PSTACK.md](PSTACK.md). Grill is [GRILL.md](GRILL.md). Voice is [VOICE.md](VOICE.md).

## Anti-patterns

- Declaring **delivered** with CI red/pending
- full_feature on every small bug
- Main thread writing product code
- PR without thermo `fix all`
- Shipping without TDD evidence on behavior change
- Auto-merge
- Interviewing the user through the grill tree
