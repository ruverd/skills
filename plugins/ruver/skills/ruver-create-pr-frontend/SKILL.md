---
name: ruver-create-pr-frontend
description: Orchestrates PR description generation for empath-ui. Use whenever the user asks to "create a PR for frontend", "generate PR description", "draft PR body", or similar in the frontend repo. Spawns parallel ruver-* agents (spec, diff-summarizer, coverage, risk, frontend-impact), resolves unaddressed ACs in pt-BR, and renders one fenced markdown block via ruver-pr-writer with repo_kind=frontend. Never opens the PR — the user runs gh pr create themselves.
---

# Ruver Create PR Frontend — Orchestrator

Generate a complete, professional PR description for the current frontend branch. The command file is the thin entry point; this skill owns the workflow.

```
SETUP → ANALYZE (parallel) → AC RESOLUTION (pt-BR) → WRITE → RENDER
```

## Tone

- **Final description**: English (template fields, bullets, test plan).
- **Interactive prompts**: pt-BR. Translate the author's answers into English before writing them into the description.

## Prerequisites

- `gh` authenticated only if `$ARGUMENTS` contains a dependent PR URL.
- Working tree may have uncommitted changes — the skill reads `main..HEAD`, not the index.
- Branch has ≥ 1 commit ahead of `main`.

---

## Phase A — Confirm repo and parse argument

1. Confirm we're in `empath-ui`:
   - Look for React in dependencies, `src/App/` structure, Playwright config, Frontegg deps.
   - If not → stop and print: `This command runs in empath-ui. For backend, use /ruver-create-pr-backend.`
2. Parse `$ARGUMENTS`:
   - Empty → `DEPENDENT_PR_URL = null`.
   - Looks like a GitHub PR URL → `DEPENDENT_PR_URL = <url>`.
   - Anything else → stop and ask the user (pt-BR) to clarify.

## Phase B — Collect branch context

```bash
git rev-parse --abbrev-ref HEAD
git log main..HEAD --oneline
git log main..HEAD --pretty=%s
git diff main...HEAD --stat
git diff main...HEAD
```

If `git log main..HEAD` is empty → stop. Print: `No commits ahead of main. Nothing to describe.`

Build `branch_context`:

```jsonc
{
  "repo_kind": "frontend",
  "head_branch": "...", "base_branch": "main",
  "commits": [{ "sha": "...", "subject": "..." }],
  "files_changed": ["src/..."],
  "diff_text_or_path": "...",
  "dependent_pr_url": null,
  "linear_ticket_candidates": ["..."]
}
```

## Phase C — Layer 1: ANALYZE (parallel, sonnet)

Send **one message** with five Task calls:

| Agent | Returns |
|---|---|
| `ruver-spec` | `linear_ticket`, `linear_context`, `acceptance_criteria_status[]`, `scope_creep[]` |
| `ruver-diff-summarizer` | `summary_by_area[]`, `type_of_change`, `scope` |
| `ruver-coverage` | `new_or_changed_logic[]`, `overall_assessment` |
| `ruver-risk-assessor` | `risk_level`, `why_its_safe`, `rollback_notes`, `breaking_changes[]` |
| `ruver-frontend-impact` | `ui_flows[]`, `states_to_verify[]`, `permissions_changes[]`, `shared_component_consumers[]`, `storybook_changes[]`, `visual_changes_summary` |

If `ruver-spec` returns `linear_ticket: null`, the writer will skip the Linear / Requirements sections.

## Phase D — AC resolution (pt-BR, one at a time)

For every entry in `spec.acceptance_criteria_status[]` where `status === "not_done"` OR `status === "partial"`, ask in pt-BR:

```
AskUserQuestion:
  question: "O AC \"<criterion>\" parece <não atendido | parcial>. Por que não foi incluído nesta PR?"
  header: "AC não atendido"
  options:
    - "Fora do escopo desta PR — tratado em outro lugar"
    - "Planejado para uma PR futura"
    - "Já foi feito em uma PR anterior"
    - "Não se aplica — explicar (Other)"
```

Same rules as backend skill:

- One question at a time.
- "Já foi feito em uma PR anterior" → re-classify as `addressed`.
- "It IS addressed" → ask where in pt-BR and re-classify.
- Translate explanation into English as `author_explanation_en`.
- Never silently drop a `not_done` AC.

Skip Phase D entirely if Linear ticket is null OR `acceptance_criteria_status[]` is empty.

## Phase E — Layer 2: WRITE (sonnet)

Invoke `ruver-pr-writer` with:

```jsonc
{
  "repo_kind": "frontend",
  "branch_context": { /* ... */ },
  "agent_results": {
    "spec": { /* ... */ },
    "diff_summarizer": { /* ... */ },
    "coverage": { /* ... */ },
    "risk_assessor": { /* ... */ },
    "frontend_impact": { /* ... */ }
  },
  "dependent_pr_url": null
}
```

The writer returns a single rendered markdown body matching the strict frontend template (documented in `ruver-pr-writer.md`).

## Phase F — Render

Print exactly ONE fenced markdown block containing the writer's output verbatim.

After the block, print:

```
Next: gh pr create --base main --body-file <file>  →  then /ruver-code-review <PR_URL>
```

Do **not** auto-run `gh pr create`. Do **not** auto-invoke `/ruver-code-review`.

---

## Hard rules

- Confirm repo is `empath-ui` before doing anything.
- Auth flow is passwordless-only. If the diff introduces password-based UI, flag in `risk_assessor` output and surface in `Why It's Safe` section.
- Final description in English; interactive prompts in pt-BR.
- One fenced markdown block as the deliverable.
- Frontend template uses a table for Requirements (existing convention); other sections use bullets.
- Never invent UI flows, ACs, or test steps that aren't in the diff.
- Never auto-create the PR or auto-run review.

## Failure modes

| Situation | Action |
|---|---|
| Not in `empath-ui` | Stop. Suggest `/ruver-create-pr-backend`. |
| No commits ahead of main | Stop. Print message. |
| `$ARGUMENTS` non-empty and not a GitHub PR URL | Stop. Ask author (pt-BR) to clarify. |
| `ruver-spec` says Linear ticket not found | Ask author (pt-BR) for ticket key or "Sem ticket". Continue without Linear sections if "Sem ticket". |
| Linear MCP unreachable | Ask author (pt-BR) to paste ACs. Continue. |
| Diff is purely service-layer (no UI) | `ruver-frontend-impact` drops UI Flows from the test plan and leans on hook tests. |
| Diff too large to read fully | Read stat + sample biggest files. Note partial coverage in `Notes for Reviewer`. |
| `ruver-pr-writer` returns malformed output | Stop. Show what was returned. Ask user. |
