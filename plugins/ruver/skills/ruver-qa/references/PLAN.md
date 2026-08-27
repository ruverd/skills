# QA test plan (from the PR diff)

Write `.ruver-qa/PLAN.md` **before** any Playwright or browser step.
Do not execute until the inventory and numbered steps exist.

Source of truth for *how* to plan. Execute walks that file.

## Inputs

```bash
gh pr view "$PR" --json number,title,url,body,files,headRefOid,headRefName
gh pr diff "$PR" --name-only
```

Also: Linear ACs when `DEV-\d+` exists; envelope `QA_REQUEST` ACs.

Never invent ACs. If Linear is down, plan from PR body + diff only.

## Inventory

Classify every changed path (skip lockfiles, generated graphql
types unless the query/mutation itself changed):

| Path prefix | Kind | Surface to exercise |
|---|---|---|
| `src/App/<Feature>/` | screen | Route constant (`*Route`) + that page |
| `src/shared/components/` | widget | Screens that import it |
| `src/shared/ui/` | visual | Desktop **and** mobile of host screens |
| `src/shared/service/` | REST | HTTP path + UI that calls the hook |
| `src/shared/graphql/` | GraphQL | Operation name + UI that uses it |
| `src/shared/hooks/`, `contexts/` | state | Every screen that reads that state |
| API routes / handlers / controllers / services (empath-api-v2) | endpoint + **FE screen** | HTTP method/path **and** the UI route that calls it. Backend-only PRs still get a FE step. |
| `tests/`, `*.spec.ts` | e2e spec | Run that spec (`--video=on`) |
| auth, router, middleware, flags | cross-cut | Full relevant suite or user-asked e2e |

One row per distinct **surface** (route, endpoint, or spec). Group
files that only exist to serve the same screen.

## Steps

Each step is one user-visible path or one endpoint check:

```markdown
### S<n> — <short title>
- files: <paths from this PR>
- kind: screen | endpoint | state | visual | spec
- route: </path or n/a>
- endpoint: <METHOD /path or GQL op or n/a>
- acs: <AC ids / quotes this step covers>
- how:
  1. ...
- playwright: <spec or none>
- variants: happy | empty | error | flag-off | unauthorized
- pass_if: <observable>
```

Rules:

- Happy path of every AC the PR claims.
- Variants the change actually touches — not a generic checklist.
- Other screens that **read the same state**.
- Desktop + mobile only when layout/CSS changed.
- Prefer an existing Playwright spec that already covers the route.
- Full `npm run test:e2e` only if the user asks or the change is
  auth / router / middleware.
- Targeted REST/GQL checks when the PR changes a service/endpoint
  even if a spec already exists (spec can miss the contract).
- **Backend-only PR:** still add ≥1 **screen** step. Map the changed
  handler/service to the frontend route(s) that call it (empath-ui
  hooks/pages). Exercise that route in the browser. `kind: spec` /
  `git show` / unit/CI alone is **not** a complete plan.

## Gate before execute

PLAN.md must have: inventory table, ≥1 step, `pass_if` on every
step. Empty plan → stop and ask (no surface found).

Chat PT-BR: list the steps in one short block, then execute.
Do not wait for approval unless the user asked to review the plan.
