# Node: admit

**Verb:** route  
**Capability:** write JOBS, maybe spawn worker

Follow `~/.agents/skills/ruver-bus/JOBS.md`.

1. Init `.ruver-bus/JOBS.md` if missing.
2. `job_id` = `rev-pr-<n>` (or `rev-<branch>`).
3. Idle main + **one** PR → `lane=foreground`, write
   `.ruver-reviewer/STATE.md`, then **resolve**.
4. Busy main, **or** 2+ PRs in this call → one worker +
   worktree **per PR**. Orchestrator does not review diffs.
   Each worker runs `ruver-code-review` for that PR only.
   No `ruver_reviewer` spawn. No Playwright.

Worker writes `jobs/<id>/RESULT.md`. Aggregate in chat.
