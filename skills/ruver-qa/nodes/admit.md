# Node: admit

**Verb:** gate  
**Capability:** read/write JOBS queue only

Follow `../../ruver-bus/JOBS.md` “Enqueue or start QA”.
Load `ruver-memory` (read both files). Chat follows that skill.

1. Init `.ruver-bus/JOBS.md` if missing.
2. `job_id` = envelope `job_id` or `qa-pr-<n>`.
3. Decide whether the slot is free — the four conditions in
   `../../ruver-bus/JOBS.md`. Empty and this-id are two of them. Expired and
   abandoned claims are the other two, and they are the common case once a
   session has died mid-QA.
4. Free → claim `qa_active` + `qa_claimed_at`, write `.ruver-qa/STATE.md`
   (`job_id`), then **resolve**. Took over a claim? Log it and say so in chat
   before resolving.
5. Held by **another live** id → append `qa_waiting`,
   park the envelope at `jobs/<id>/qa-request.md`.
   Do **not** change `.ruver-qa/STATE.md`.
   Do **not** start e2e, browser, HTTP QA, or plan.
   Chat (`ruver-memory`): queue + position. **Stop.**

Never two QA `execute` runs.
