---
name: ruver-qa
description: >
  Graph: QA a GitHub PR. One slot (queue extras). Plan from the
  diff, then Playwright + browser. Bus TRIAGE_REQUEST on product
  errors. Use when /ruver-qa, /ruver_qa, or a QA_REQUEST arrives.
argument-hint: "<PR url or owner/repo#N>"
---

# Ruver QA (graph)

Orchestrator. You do **not** make the final bug call.

**REQUIRED:** [GRAPH.md](GRAPH.md) · [STATE.schema.md](STATE.schema.md) ·
`ruver-bus` PROTOCOL.md ·
[DISK.md](../ruver-bus/DISK.md) (`.ruver-*` is **global**, never git root)

Chat PT-BR. PR link required (args or envelope).

Init `.ruver-qa/STATE.md`. Walk GRAPH:
**admit → resolve → plan → execute**.
`admit` claims the single QA slot or **enqueues** (never two
Playwright runs). `plan` writes `.ruver-qa/PLAN.md` from the diff
before any test. Spawn execute nodes only.
Outbound triage → **bus switch** to `triage`. Never spawn `ruver_triage`.

On `TRIAGE_RESULT`, continue at **verdict** (do not re-run execute).
When done: publish **video** via `scripts/publish-evidence.sh` (never
`gh gist create` on binaries), **post `gh pr comment` with QA + video**
([references/COMMENT.md](references/COMMENT.md)), then write `QA_RESULT`
and **pop** the bus stack. Chat-only is not done.

Backend-only PRs: plan still maps the API change to the **frontend
route** that calls it, exercises that screen, and records video.
Unit/CI/`git show` alone is not a complete QA execute.
