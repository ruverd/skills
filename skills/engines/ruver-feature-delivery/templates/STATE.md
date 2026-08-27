---
schema_version: 4
status: init
spec_path: ""
tickets_path: ""
current_ticket: ""
seams: ""
goal: ""
goal_source: ""
repo: ""
branch: ""
base_branch: main
started_at: ""
updated_at: ""
autonomy: smart
open_pr: true
tdd: required
chat_language: en
work_kind: ""
path: ""
scope: ""
route_confidence: ""
route_reason: ""
linear_id: ""
linear_url: ""
linear_branch: ""
linear_context_path: ".ruver-feature-delivery/linear-context.md"
mcp_gate: ""
mcp_gate_error: ""
fullstack_run_id: ""
worktrees_frontend: ""
worktrees_backend: ""
repos_frontend: "empath-ui"
repos_backend: "empath-api-v2"
review_fix_loops: 2
review_fix_loops_used: 0
test_fix_loops: 2
test_fix_loops_used: 0
ci_fix_loops: 5
active_runtime: ""
decision_mode: ""
decision_confidence: ""
---

# Ruver feature delivery — state

## MCP gate

- **mcp_gate:** pending | passed | passed_partial | failed (enum: STATE.schema.md)
- **error:** (if failed — full message to the user, English)

## MCP sources

| source | critical | status | path / notes |
|--------|----------|--------|--------------|
| linear | | | |
| figma | | | |
| sentry | | | |
| notion | | | |
| other | | | |

Index: `.ruver-feature-delivery/mcp-sources.md`

## Linear

- **ID:**
- **URL:**
- **Branch (gitBranchName / feature/dev-xxxx):**
- **Context file:** `.ruver-feature-delivery/linear-context.md`
- **Comments loaded:** no
- **Related loaded:** no

## Route (triage)

- **work_kind:** feature | bug | regression | chore | spike
- **scope:** frontend_only | backend_only | fullstack
- **path:** full_feature | debug_fix | light_change
- **confidence:**
- **reason:**

## Fullstack (if scope=fullstack)

- **branch (same both repos):**
- **run_id:**
- **backend worktree / task / PR:**
- **frontend worktree / task / PR:**

## Blockers / wait

- **status:** none | waiting_blocker | unblocked
- **blockers:**
  - id:
    role: api_contract | ticket | product
    draft_created:
    last_check:
- **advanced_while_waiting:**

## Debug (debug_fix path only)

- **Root cause:**
- **Evidence:**
- **Hypotheses tried:**
- **fix_slice:** (text for the coder)

## Done criteria

- [ ] (from spec / tickets)

## Spec

- **path:** `.ruver-feature-delivery/SPEC.md`

## Tickets

- **path:** `.ruver-feature-delivery/TICKETS.md`
- **current:**
- **seams:**

## Decisions

<!--
- ISO | DECIDE|ASK
  - Choice:
  - Who: agent | user
  - Confidence:
  - Evidence:
  - Residual risk:
-->

## Question to the user (if waiting_user)

- **Question:**
- **Options:**
- **Answer:**

## TDD evidence

<!--
- behavior:
  - test:
  - red:
  - green:
-->

## Context whitelist notes

- Detect test/typecheck scripts in the repo.
- Prefer the neighbor feature's pattern.

## Files touched

## Review

- **Verdict:** pending
- **Summary:**
- **Findings:**
- **TDD check:** pending

## Test / hard gate

- **Hard gate:** pending
- **Commands run:**
- **Summary:**

## Blast radius

- **Safety fact:**
- **Proven:** no | yes (command)
- **Unproven:**
- **Summary:**

## Quality (thermo-nuclear)

- **Status:** pending | done | blocked
- **Mode:** fix all
- **Findings fixed:**
- **Remaining:**
- **Hard gate after:** pending
- **Summary:**

## Ship

- **Commit:** none
- **Pushed:** no
- **PR:** none
- **Summary for human (English):**

## CI (delivery)

- **ci.status:** pending | watching | fixing | green | escalated | skipped_no_pr
- **pr_url:**
- **fix_loops_used:** 0
- **checks_summary:**
- **delivered:** no   # yes only if green (or explicit skipped_no_pr)

## Handoff / continuity

- **handoff_ready:** no
- **from_runtime:**
- **to_runtime:**
- **handoff_path:** .ruver-feature-delivery/HANDOFF.md

## Escalations

## Lessons

## Run log
