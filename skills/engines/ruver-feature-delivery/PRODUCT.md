# Product — current repo, not this plugin

Graphs never name a company, org, or sibling repo. Read this at
`mcp_context`, triage, shipper, and QA plan.

## Topology

From the **current git root** (DECIDE, log in STATE `scope`):

| Signals in this root | `scope` |
|---|---|
| UI (react/next/vite, Playwright, `components.json`, `app/`, `pages/`, `src/App`) and no API | `frontend_only` |
| API (prisma, elysia, express, nest, OpenAPI, controllers, `src/modules`) and no UI | `backend_only` |
| Both in **this** git root (`apps/web` + `apps/api`, …) | `mono` |
| Ticket/goal needs UI **and** API, this root is only one side | `fullstack` if a sibling resolves; else stay on this repo |

`mono` is one checkout, both surfaces. Not two worktrees.

## Sibling (split FE / BE)

Only when `scope` would be `fullstack`. Order:

1. `$RUVER_FRONTEND` / `$RUVER_BACKEND` (repo name or path)
2. Current repo `AGENTS.md` section `## Product (ruver)` keys `frontend` / `backend`
3. If `orca` is on PATH **and** `orca status --json` works: `orca project list --json` to resolve those names
4. Else stay on this repo. Do not invent a sibling.

ASK only if the ticket cannot be done without the other side and nothing above resolved it.

## Assignee and reviewers

GitHub **assignee:** `AGENTS.md` if listed, else `gh api user --jq .login`.
Never `git config user.name` (a display name is not a GitHub login).

GitHub **reviewers:** `AGENTS.md` if listed. Else let `CODEOWNERS` run on PR
open. Do not invent handles.

Linear **NEW_BUG** assignee: the session Linear user (match git email).
Never a hardcoded person.

## QA surfaces

Classify the **PR diff**. No baked folder map.

- UI in this repo: browser + video on the routes the diff touches.
- API only, no `$RUVER_FRONTEND` and no UI in-repo: HTTP the changed
  endpoints. Do **not** invent a screen. Video/evidence of the HTTP
  calls is enough.
- API + resolved frontend sibling: map to a FE route if a caller
  exists; else HTTP.

## CI

Poll required checks ~5 min. No assumed duration.
Skip locally when the command is expected **>10 min**, or listed in
`AGENTS.md` / `$RUVER_CI_LOCAL_SKIP`.

## Orca

Optional. Never a gate. Default: `git worktree` + host `spawn_worker`
([HOST.md](../../../HOST.md)). If `orca` works, worktrees may go
through it. Host subagents are the real workers, not a fake.
