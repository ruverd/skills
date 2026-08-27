# Node: deliver

**Verb:** run fd  
**Capability:** orchestrate only — load `ruver-feature-delivery` GRAPH

## Mission

Run **ruver-feature-delivery** on the goal until `status=done` (CI green)
or a terminal fd state (`waiting_blocker`, `escalated`, `done_local`).

Do not re-implement fd. Do not write product code.
If `lane=worker`, work only in `worktree` (or host isolation).

## Output

`fd_status` + `pr_url` + `sha` into developer STATE.

When a draft PR exists and CI is not yet green, start **ruver-goal**
wait loop (`~/.agents/skills/ruver-goal/references/LOOP.md`). Do not
block this turn on `--watch`.
