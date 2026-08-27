# Node: fullstack_setup (+ coordinate)

**Verb:** coordinate
**Capability:** Orca CLI (worktree + orchestration); write STATE
**When:** `scope: fullstack` after triage

## Mission

1. Create/reuse **Orca worktrees** on frontend and backend with the **same branch**.
2. Create **Run + tasks + workers** via `orca orchestration` to run the task in both repos.
3. Wait for `worker_done` / handle asks; aggregate the result.

Follow [FULLSTACK.md](../FULLSTACK.md).
Live guides: `orca skills get orca-cli` and `orca skills get orchestration`.

## Steps

1. Confirm `orca status --json` (runtime up).
2. Resolve `linear_branch` (STATE) = unique name.
3. `orca worktree create` (or reuse) on **backend** and **frontend** with `--name <branch>`.
4. `orca orchestration run-create`.
5. `task-create` BE and FE (deps if contract).
6. `worker-start` on each worktree/repo.
7. Loop `check` until done/escalation.
8. Update STATE: run_id, task ids, worktree paths, status per repo.

## Output

```text
result: ok | blocked | partial
branch: feature/dev-1212
backend_worktree: ...
frontend_worktree: ...
run_id: ...
backend_task: ...
frontend_task: ...
```

## Hard rules

- Same branch on both repos.
- Real orchestration (verifiable task-list/dispatch) — do not fake it with local
  runtime subagents (Task tool on Claude / agent() on Grok).
- Linear MCP for the ticket; Orca for worktrees/workers.
- No automatic merge.
