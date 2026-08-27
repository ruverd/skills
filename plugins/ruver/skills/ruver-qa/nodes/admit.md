# Node: admit

**Verb:** gate  
**Capability:** read/write JOBS queue only

Follow `~/.agents/skills/ruver-bus/JOBS.md` “Enqueue or start QA”.

1. Init `.ruver-bus/JOBS.md` if missing.
2. `job_id` = envelope `job_id` or `qa-pr-<n>`.
3. If `qa_active` is empty or **this** id → claim `qa_active`,
   write `.ruver-qa/STATE.md` (`job_id`), then **resolve**.
4. If `qa_active` is **another** id → append `qa_waiting`,
   park the envelope at `jobs/<id>/qa-request.md`.
   Do **not** change `.ruver-qa/STATE.md`.
   Do **not** start Playwright, browser, or plan.
   Chat PT-BR: fila + posição. **Stop.**

Never two QA `execute` runs.
