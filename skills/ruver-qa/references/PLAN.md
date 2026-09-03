# QA test plan (from the PR diff)

Write `.ruver-qa/PLAN.md` **before** any browser or HTTP step.
Do not execute until the inventory and numbered steps exist.

Source of truth for *how* to plan. Execute walks that file.

## Inputs

```bash
gh pr view "$PR" --json number,title,url,body,files,headRefOid,headRefName
gh pr diff "$PR" --name-only
```

Also: tracker ACs when a ticket id exists; envelope `QA_REQUEST` ACs.

Never invent ACs. If the tracker is down, plan from PR body + diff only.

## Inventory

Classify every changed path (skip lockfiles, generated graphql
types unless the query/mutation itself changed):

| Path kind (match the diff, not a baked tree) | Kind | Surface to exercise |
|---|---|---|
| Pages / routes / screens (`app/`, `pages/`, `src/App`, views) | screen | That route |
| Shared components | widget | Screens that import it |
| Design system / `ui` | visual | Desktop, and mobile only if layout/CSS/media/DS changed |
| API client / hooks / services | REST | HTTP path + UI that calls it (if UI exists) |
| GraphQL operations | GraphQL | Operation name + UI that uses it |
| hooks / contexts / state | state | Every screen that reads that state |
| API routes / handlers / controllers / services | endpoint | HTTP method/path. FE screen **only if** a frontend exists in-repo or `$RUVER_FRONTEND` resolves ([PRODUCT.md](../../ruver-feature-delivery/PRODUCT.md)) |
| `tests/`, `*.spec.ts` | skip | App CI owns the spec. Do not add an execute step for it |
| auth, router, middleware, flags | cross-cut | The user-visible routes those files gate |

One row per distinct **surface** (route or endpoint). Group
files that only exist to serve the same screen.

## Steps

Each step is one user-visible path or one endpoint check:

```markdown
### S<n> — <short title>
- files: <paths from this PR>
- kind: screen | endpoint | state | visual
- route: </path or n/a>
- endpoint: <METHOD /path or GQL op or n/a>
- acs: <AC ids / quotes this step covers>
- how:
  1. ...
- variants: happy | empty | error | flag-off | unauthorized
- pass_if: <observable>
```

Rules:

- If any step is an authenticated screen, S1 (or an explicit setup step) is **log in** via session restore, then the repo helper if restore missed. Later steps assume a session.
- Happy path of every AC the PR claims.
- Variants the change actually touches — not a generic checklist.
- Other screens that **read the same state**.
- Desktop + mobile only when layout/CSS/media/DS changed.
- Do not name or run an e2e spec. `qa_tool` is `agent-browser` or `http`.
- Targeted REST/GQL checks when the PR changes a service/endpoint
  even if a screen step exists (the walk can miss the contract).
- **Backend-only PR, no frontend sibling:** HTTP the changed
  endpoints. Do not invent a screen. Evidence of those calls is
  enough. `git show` / unit/CI alone is still not a complete plan.
- **Backend-only PR with a resolved frontend:** map the handler to
  the UI that calls it and exercise that route. If no caller exists,
  HTTP only.

## Gate before execute

PLAN.md must have: inventory table, ≥1 step, `pass_if` on every
step. Empty plan → stop and ask (no surface found).

Chat (`ruver-memory`): list the steps in one short block, then execute.
Do not wait for approval unless the user asked to review the plan.
