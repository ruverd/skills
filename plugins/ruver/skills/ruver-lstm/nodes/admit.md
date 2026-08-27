# Node: admit

**Verb:** route
**Capability:** write JOBS, maybe spawn worker

Follow `~/.agents/skills/ruver-bus/JOBS.md`.

1. Init `.ruver-bus/JOBS.md` if missing.
2. `job_id` = `lstm-pr-<n>` (or `lstm-<branch>`).
3. Idle main + **one** PR → `lane=foreground`, write
   `.ruver-lstm/STATE.md`, then **resolve**.
4. Busy main, **or** 2+ PRs in this call → one worker +
   worktree **per PR**. Orchestrator does not patch diffs.
   Each worker runs this skill for that PR only.
   No `ruver_lstm` / `ruver_developer` spawn.

Worker writes `jobs/<id>/RESULT.md`. Aggregate in chat.
