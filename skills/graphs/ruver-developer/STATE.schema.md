# Developer STATE

**Path:** `.ruver-developer/STATE.md`

## status

```
init | delivering | fixing | mergeable | qa_requested | applying_qa | waiting_user | done | done_notes | escalated | handed_off
```

## Fields

| Field | Use |
|---|---|
| `mode` | delivery \| fix |
| `goal` | user text; enough to start without Linear |
| `fd_status` | mirror of fd graph if delivery |
| `pr_url` | draft PR |
| `sha` | head |
| `ci` | pending \| green \| red |
| `mergeable` | MERGEABLE \| … |
| `qa_verdict` | after QA_RESULT (`PASS`/`FAIL`/`BLOCKED`) |
| `triage_class` | rollup from QA notes when present |
| `job_id` | bus JOBS id (`dev-DEV-XXXX`) |
| `lane` | `foreground` \| `worker` |
| `worktree` | path if lane=worker |
| `worker_id` | spawn id if lane=worker |

Orchestrator writes `status`. Nodes write their section only.
