# Linear for bug triage

Use the session Linear MCP (`search_tool` then `use_tool`). Do not invent
issue ids. Do not use `orca linear`.

## When to search

Once **per finding**, and only after that finding is a **real
product bug** and **not PR-related** (`NEW_BUG` candidate).
`PR_BUG` findings never get a ticket.

Search the workspace for the same **underlying** problem (title, symptoms,
feature, endpoint, component). Wording differences are not a new bug.

Search GitHub-linked work for both:

- `EmpathMSP/empath-ui`
- `EmpathMSP/empath-api-v2`

Typical calls:

- `Linear__list_issues` with `query` = symptoms / feature / endpoint
- include archived / done so you can detect a regression
- `Linear__list_teams` if you need a team name before create

## Existing issue

| State | Same underlying bug | Action |
|---|---|---|
| Todo / In Progress / Blocked / unresolved | yes | `EXISTING_BUG` — cite it |
| Done / Canceled / resolved | yes, and still reproduces | Investigate regression vs incomplete fix vs lookalike. New ticket only if it is a genuine unresolved problem not already represented |
| any | different problem | ignore |

## Create ticket (`NEW_BUG` only)

**One ticket per `NEW_BUG` finding.** Two unrelated findings → two
issues. Do not bundle. Do not create a ticket for `PR_BUG`.

All four must hold for **that** finding:

1. Confirmed real product bug
2. Unrelated to the current PR
3. No open Linear covers it
4. Not already resolved

`Linear__save_issue`:

- `title` — actionable (what + where)
- `team` — discover via `list_teams` (never hardcode a UUID)
- `assignee` — `Ruver Dornelas`
- `state` — `Todo`
- `labels` — include `Bug` if that label exists
- `links` — `{ url: <PR link>, title: "Discovered during QA" }`
- `description` must answer: what / where / repro / expected / actual /
  frequency / FE or BE component / endpoint / discovery PR / evidence

Keep the **original PR link** in the ticket even though the bug is
unrelated — that is the discovery context.

Refuse vague tickets ("Something is broken.").
