---
name: ruver-create-pr-backend
description: Orchestrates PR description generation for empath-api-v2. Use whenever the user asks to "create a PR for backend", "generate PR description", "draft PR body", or similar in the backend repo. Spawns parallel ruver-* agents (spec, diff-summarizer, coverage, risk, backend-impact), resolves unaddressed ACs in pt-BR, and renders one fenced markdown block via ruver-pr-writer with repo_kind=backend. Never opens the PR — the user runs gh pr create themselves.
---

# Ruver Create PR Backend — Orchestrator

Generate a complete, professional PR description for the current backend branch. The command file is the thin entry point; this skill owns the workflow.

```
SETUP → ANALYZE (parallel) → AC RESOLUTION (pt-BR) → WRITE → RENDER
```

## Tone

- **Final description**: English (template fields, bullets, test plan).
- **Interactive prompts**: pt-BR. Translate the author's answers into English before writing them into the description.

## Prerequisites

- `gh` authenticated only if `$ARGUMENTS` contains a dependent PR URL (to validate it).
- Working tree may have uncommitted changes — the skill reads `main..HEAD`, not the index.
- Branch has ≥ 1 commit ahead of `main`.

---

## Phase A — Confirm repo and parse argument

1. Confirm we're in `empath-api-v2`:
   - Look for Elysia in dependencies, `src/modules/v1/` structure, `package.json` name.
   - If not → stop and print: `This command runs in empath-api-v2. For frontend, use /ruver-create-pr-frontend.`
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
  "repo_kind": "backend",
  "head_branch": "...", "base_branch": "main",
  "commits": [{ "sha": "...", "subject": "..." }],
  "files_changed": ["src/..."],
  "diff_text_or_path": "...",
  "dependent_pr_url": null,
  "linear_ticket_candidates": ["..."]  // from branch name + commit subjects
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
| `ruver-backend-impact` | `affected_endpoints[]`, `migrations[]`, `jobs[]`, `repositories_services[]`, `schema_changes[]`, `cache_invalidations[]` |

If `ruver-spec` returns `linear_ticket: null`, the writer will skip the Linear / Requirements sections.

## Phase D — AC resolution (pt-BR, one at a time)

For every entry in `spec.acceptance_criteria_status[]` where `status === "not_done"` OR `status === "partial"`, ask the author in pt-BR:

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

Rules:

- One question at a time. Wait for each answer before asking the next.
- If the author picks "Já foi feito em uma PR anterior" → re-classify the AC as `addressed`.
- If the author says it IS addressed and the agent missed it → ask where (pt-BR) and re-classify.
- Translate the captured explanation into concise English and attach to the AC entry as `author_explanation_en`.
- Never silently drop a `not_done` AC. If the author refuses, write `_no explanation provided_` and keep it visible.

If Linear ticket is null OR `acceptance_criteria_status[]` is empty → skip Phase D entirely.

## Phase E — Layer 2: WRITE (sonnet)

Invoke `ruver-pr-writer` with:

```jsonc
{
  "repo_kind": "backend",
  "branch_context": { /* ... */ },
  "agent_results": {
    "spec": { /* ... */ },
    "diff_summarizer": { /* ... */ },
    "coverage": { /* ... */ },
    "risk_assessor": { /* ... */ },
    "backend_impact": { /* ... */ }
  },
  "dependent_pr_url": null
}
```

The writer returns a single rendered markdown body matching the strict backend template (documented in `ruver-pr-writer.md`).

## Phase F — Render

Print exactly ONE fenced markdown block (using ` ```markdown ` … ` ``` `) containing the writer's output verbatim. The user can copy the raw content into `gh pr create --body-file` or the GitHub UI.

After the fenced block, print a one-line reminder:

```
Next: gh pr create --base main --body-file <file>  →  then /ruver-code-review <PR_URL>
```

Do **not** auto-run `gh pr create`. Do **not** auto-invoke `/ruver-code-review`.

---

## Hard rules

- Confirm repo is `empath-api-v2` before doing anything.
- Final description in English; interactive prompts in pt-BR.
- One fenced markdown block as the deliverable.
- Never markdown tables — bullets only (project convention).
- Never invent endpoints, ACs, or test steps that aren't in the diff.
- Never auto-create the PR or auto-run review.

## Failure modes

| Situation | Action |
|---|---|
| Not in `empath-api-v2` | Stop. Suggest `/ruver-create-pr-frontend`. |
| No commits ahead of main | Stop. Print message. |
| `$ARGUMENTS` non-empty and not a GitHub PR URL | Stop. Ask author (pt-BR) to clarify. |
| `ruver-spec` says Linear ticket not found | Ask author (pt-BR) for ticket key or "Sem ticket". Continue without Linear sections if "Sem ticket". |
| Linear MCP unreachable | Ask author (pt-BR) to paste ACs. Continue. |
| Diff too large to read fully | Read the stat, sample biggest files. `ruver-backend-impact` parses controllers/types first so `Affected Endpoints` stays accurate. Note partial coverage in `Notes for Reviewer`. |
| `ruver-backend-impact` cannot parse Elysia prefix | Move the route into `Notes for Reviewer` for author confirmation. |
| `ruver-pr-writer` returns malformed output | Stop. Show what was returned. Ask user. |
