# Node: admit

**Verb:** route  
**Capability:** write JOBS, maybe spawn worker

Follow `~/.agents/skills/ruver-bus/JOBS.md`.

1. Init `.ruver-bus/JOBS.md` if missing.
2. `job_id` = `dev-<DEV-XXXX>` or `dev-pr-<n>`.
3. Idle main → `lane=foreground`, write
   `.ruver-developer/STATE.md` (`job_id`, `lane`), then
   **deliver** or **fix**.
4. Busy main → worktree + one `general-purpose` worker.
   Do not steal QA/triage/the other job. Stop this call.

Worker prompt: job id, worktree, ticket/PR, load
`ruver-developer` + `ruver-feature-delivery`, execute nodes
**inline** (no `ruver_*` / `ruver-fd-*` spawns), never merge,
write `jobs/<id>/RESULT.md`.
