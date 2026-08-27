---
name: ruver-validate-branch
description: Orchestrates pre-PR local validation for empath-ui and empath-api-v2. Use whenever a branch validation is requested via `/ruver-validate-branch` or when the user asks to "validate this branch", "check before pushing", "ready to push?", or similar. Spawns parallel ruver-* specialist auditors, resolves ambiguities with the author in pt-BR, applies fixes, runs /simplify, writes missing tests, and verifies the build is green before offering to push. Includes ralph-loop for large branches. In PR mode, loops with /ruver-code-review until approved.
---

# Ruver Validate Branch — Orchestrator

Pre-PR validation pipeline. Take a branch from "I think it's done" to "ready to merge".

```
SETUP → ANALYZE (parallel) → DECIDE → AMBIGUITIES (pt-BR) →
  FIX → SIMPLIFY → TESTS → VERIFY → PUSH/PR → SUMMARY
```

The command file is the thin entry point; this skill owns the workflow.

## Tone

- **Final diff, commits, PR body, summary**: English (Conventional Commits).
- **Interactive prompts to the author**: Portuguese (pt-BR), grill-me style — one question at a time, with a recommended answer.

## Prerequisites

- `gh` authenticated.
- Branch has ≥ 1 commit ahead of `main` (or `master`).
- Working tree clean — if dirty, ask in pt-BR whether to stash, commit, or stop. Don't silently leave changes uncommitted (the FIX stage will commit).

---

## Stage 0 — Setup

Pick the mode by `$ARGUMENTS`:

- **PR mode** — `$ARGUMENTS` is a URL or plain number.
  - Parse `OWNER`, `REPO`, `PR_NUMBER`. URL → split. Plain number → use `origin` of current repo.
  - `gh pr view PR_NUMBER --repo OWNER/REPO --json headRefName,headRefOid,baseRefName,isDraft,mergeStateStatus,state`.
  - Save `HEAD_SHA`, `BASE_BRANCH`, `HEAD_BRANCH`.
  - Verify local branch matches `HEAD_BRANCH`. If not → ask in pt-BR whether to `git checkout HEAD_BRANCH` or stop.
  - Set `PR_REF = OWNER/REPO#PR_NUMBER`. Set `HAS_PR = true`.

- **Pre-PR mode** — `$ARGUMENTS` empty.
  - `HEAD_BRANCH` = current branch. Reject if it equals base.
  - `BASE_BRANCH` = `main` (or `master`).
  - Check `gh pr list --head <HEAD_BRANCH> --json number,url,state`. If a PR already exists, ask in pt-BR whether to switch to PR mode or stay local-only.
  - Set `HAS_PR` accordingly.

Detect:

- **Package manager** from lockfile: `bun.lockb` → bun, `pnpm-lock.yaml` → pnpm, `yarn.lock` → yarn, `package-lock.json` → npm. Save as `PM`.
- **Repo kind** from package.json / structure:
  - `empath-ui` indicators: React in deps, `src/App/`, Playwright config, Frontegg deps. → `repo_kind: frontend`.
  - `empath-api-v2` indicators: Elysia in deps, `src/modules/v1/`, Bun in scripts, Prisma. → `repo_kind: backend`.
  - Other → `repo_kind: generic` (run all auditors).

## Stage 1 — Gather context

```bash
git log main..HEAD --oneline
git diff main...HEAD --stat
git diff main...HEAD
```

Build `branch_context`:

```jsonc
{
  "head_branch": "...", "base_branch": "main",
  "head_sha": "...",
  "repo_kind": "frontend | backend | generic",
  "package_manager": "bun | npm | pnpm | yarn",
  "commits": [{ "sha": "...", "subject": "..." }],
  "files_changed": ["src/..."],
  "diff_size": { "total_lines": 0, "additions": 0, "deletions": 0, "files_count": 0 },
  "diff_text_or_path": "..."
}
```

### Strategy pick

- `diff_lines < 3000` AND `files_count < 30` → **standard** Phase 2.
- Otherwise → **ralph-loop** for `ruver-react-auditor` / `ruver-node-bun-auditor` / `ruver-ts-auditor`. Pattern documented in `ruver-code-review/SKILL.md` — same workspace at `~/.ruver/ralph/<owner>/<repo>/branch-<sha>/<agent>/`.

## Stage 2 — Layer 1: ANALYZE (parallel, sonnet)

Send **one message** with the relevant Task calls. Skip auditors irrelevant to `repo_kind`:

| Agent | When | Returns |
|---|---|---|
| `ruver-react-auditor` | `repo_kind in {frontend, generic}` | `findings[]` (React-specific) |
| `ruver-node-bun-auditor` | `repo_kind in {backend, generic}` | `findings[]` (Node/Bun-specific) |
| `ruver-ts-auditor` | always | `findings[]` (TS-specific) |
| `ruver-standards` | always | `standards_violations[]`, `simplify_suggestions[]`, `architecture_improvements[]` |
| `ruver-security` | always | `findings[]` (HIGH confidence ≥ 8) |
| `ruver-coverage` | always | `new_or_changed_logic[]`, `overall_assessment` |

All agents are read-only. None of them edit files or run shell commands.

Capture `agent_errors[]` for any agent that returns malformed JSON; the decider tolerates partial input.

## Stage 3 — Layer 2: DECIDE + AMBIGUITY ROUTING (sonnet)

Invoke `ruver-validate-decider` with:

```jsonc
{
  "branch_context": { /* ... */ },
  "agent_results": {
    "react": { /* if invoked */ },
    "node_bun": { /* if invoked */ },
    "ts": { /* ... */ },
    "standards": { /* ... */ },
    "security": { /* ... */ },
    "coverage": { /* ... */ }
  },
  "agent_errors": []
}
```

The decider returns:

```jsonc
{
  "findings_consolidated": [ /* deduped, severity-classified */ ],
  "ambiguities": [
    {
      "id": "A1",
      "file": "src/...",
      "line": 42,
      "question_pt_br": "...",
      "recommended_answer_pt_br": "...",
      "options_pt_br": ["(Recomendado) ...", "...", "..."]
    }
  ],
  "tests_gaps": [
    { "file": "...", "reason": "...", "suggested_test_path": "...", "what_to_cover": "..." }
  ],
  "summary": "one paragraph: critical + important + nits + ambiguities + tests gaps"
}
```

## Stage 4 — Ambiguities (pt-BR, grill-me)

For each `ambiguities[]` item, ask in pt-BR **one at a time**:

```
AskUserQuestion:
  question: "<question_pt_br>"
  header: "Dúvida <id>"
  options: <options_pt_br with the recommendation labelled "(Recomendado)" as the first item>
```

Rules:

- One question per turn. Wait for the answer before asking the next.
- If the answer reveals a new branch of decision → follow it before continuing.
- If a question can be resolved by reading more code → read first, ask only what's still unclear.
- Capture each answer as `ambiguity.resolution` in **English** (translate from pt-BR) so it can be cited in commits and PR comments.

Skip if `ambiguities[]` is empty.

## Stage 5 — Apply fixes (orchestrator edits files)

For every `findings_consolidated[]` item with `severity` in `{critical, important}`, plus every ambiguity now resolved:

- Edit relevant files (Edit/Write tools — agents are read-only, the orchestrator writes).
- Keep changes scoped — no opportunistic refactors here. `/simplify` runs later.
- Stage and commit using Conventional Commits. One commit per logical group of fixes.
- **Do NOT push.** Push only happens at Stage 9 if/when the author approves.

Skip if nothing to fix.

## Stage 6 — `/simplify` pass

```
Skill: simplify
```

(Or `Skill: pr-review-toolkit:code-simplifier` if `simplify` is not registered — pick whichever exists. Skip and note in summary if neither is available.)

Apply only changes that preserve behavior and stay within the branch scope. Reject suggestions that expand the blast radius outside the branch.

Commit as `refactor: simplify <area>`. Do not push.

## Stage 7 — Test coverage

For every `tests_gaps[]` entry:

1. Read the nearest existing test file to copy the testing pattern (framework, helpers, mocking, naming).
2. Write the missing test at `suggested_test_path`.
3. Cover the cases in `what_to_cover`.

Run the project's test command (`<PM> test`). All new tests must pass before commit.

Commit as `test: cover <area>`. Do not push.

If the project uses BDD/`should`-prefixed naming or any other convention captured in `AGENTS.md`, follow it.

### Ralph-loop for many tests_gaps

If `tests_gaps.length > 10`, write ~3 at a time using a state file at `~/.ruver/ralph/<owner>/<repo>/branch-<sha>/tests/`. Same pattern as in `ruver-code-review/SKILL.md`.

## Stage 8 — Verify (orchestrator runs commands)

Run in parallel where the package manager supports it:

```bash
<PM> run typecheck    # skip if script missing — note in summary
<PM> run lint
<PM> test             # or <PM> run test
```

Save the outputs. If any fails:

1. Pass the failure output to a focused agent invocation (`ruver-ts-auditor` for typecheck, the standards-reviewer/react/node agent for lint runtime issues) **for parsing** — they read the output, return structured findings.
2. Apply fixes per Stage 5 logic.
3. Commit. Re-run. Max 3 fix-and-rerun cycles. If still red, stop and ask the author in pt-BR.

Never finish with a red build.

## Stage 9 — Push & PR decision (interactive pt-BR)

### HAS_PR == true

Push local commits to the PR's head branch:

```bash
git push origin HEAD_BRANCH
```

Then invoke `/ruver-code-review`:

```
Skill: ruver-code-review
args: "<PR_URL_or_number>"
```

Outcomes:

- **APPROVED** → done.
- **CHANGES_REQUESTED** → loop back to Stage 4/5 (ask in pt-BR if anything is unclear), re-push, re-run review. Max 5 iterations; if the same blocker survives 2 iterations unchanged, stop and ask the author for direction.
- **DEFERRED — draft** → ask in pt-BR whether to mark ready or stop.

### HAS_PR == false

Ask in pt-BR:

```
AskUserQuestion:
  question: "Validação local passou. O que fazer agora?"
  header: "Próximo passo"
  options:
    - "Fazer push e abrir PR (gh pr create)"
    - "Só fazer push — eu abro a PR depois"
    - "Não fazer push — só local mesmo"
```

Whichever option, do NOT push without explicit confirmation in pt-BR.

If "abrir PR" → call `/ruver-create-pr-{kind}` to generate the description first (kind from `repo_kind`), then `gh pr create --body-file <generated>`.

## Stage 10 — Print summary

```
# Branch Validation: <branch>  (PR: <PR_REF or "none">)

| Stage | Result |
|---|---|
| Strategy | <standard | ralph-loop (N iterations)> |
| Analyze | react: N · node-bun: N · ts: N · standards: N · security: N · coverage: <assessment> |
| Decide | <N critical · M important · K nits · A ambiguities · T tests-gaps> |
| Ambiguities | <resolved / none> |
| Fixes | <N commits / no changes> |
| /simplify | <commit / nothing to simplify / skill not installed> |
| Tests | <N files added / coverage already complete> |
| Verify | typecheck: <pass|fail> · lint: <pass|fail> · test: <pass|fail> |
| Push & review | <APPROVED via /ruver-code-review after N iterations | pushed + PR opened | pushed only | stayed local> |

Verdict: <READY TO MERGE | LOCAL VALIDATION PASSED — awaiting push | NOT READY — <reason>>
```

---

## Hard rules

- **Default to local-only.** Never push or open a PR without explicit author confirmation in Stage 9.
- Never silently override the author. If you disagree with an answer, raise another question.
- Never `git push --force`. Force-with-lease only if explicitly asked.
- Never amend commits made by the author. Always new commits.
- Never finish with a red build.
- Stay within the branch's scope. Out-of-scope improvements → `Notes for Reviewer` (when a PR is opened) or follow-up issue.
- Agents are read-only. Only the orchestrator edits files and runs commands.
- All commits in English. Interactive prompts in pt-BR.

## Failure modes

| Situation | Action |
|---|---|
| `gh` not logged in | Stop. Print `gh auth status`. |
| Dirty working tree | Ask pt-BR: stash, commit, or stop. |
| PR mode + PR closed/merged | Stop. Print state. |
| Branch has no commits ahead of base | Stop. Print `No commits ahead of <base>.` |
| Analysis agent returns malformed JSON | Capture error. Decider tolerates partial. |
| Stage 9 `/ruver-code-review` hits 5 iterations without approval | Stop. Dump open blockers. Ask pt-BR for direction. |
| `simplify` skill not installed | Skip Stage 6. Note in summary. |
| Test runner not configured | Skip Stage 8 test run. Still write tests in Stage 7. Flag in summary. |
| Stage 8 still red after 3 fix-and-rerun cycles | Stop. Ask pt-BR. |
