# Commands

Every slash command the graph engineer runs. Aliases with underscores
(` /ruver_developer `) are the same skill.

## Graphs (main thread)

These **are** the graph engineer. They walk a GRAPH. They do not
implement product code.

| Command | When | Page |
|---|---|---|
| `/ruver-developer` | Ticket, goal, or PR_BUG fix | [ruver-developer](ruver-developer.md) |
| `/ruver-qa` | Exercise a PR in the browser | [ruver-qa](ruver-qa.md) |
| `/ruver-triage` | Classify a QA finding | [ruver-triage](ruver-triage.md) |
| `/ruver-reviewer` | Review a PR / diagnose CI | [ruver-reviewer](ruver-reviewer.md) |
| `/ruver-lstm` | Incoming review comments | [ruver-lstm](ruver-lstm.md) |
| `/ruver-bus` | Resume or inspect the stack | [ruver-bus](ruver-bus.md) |
| `/ruver-goal` | Keep going until QA+video | [ruver-goal](ruver-goal.md) |

## Engines

Called by a graph, or run alone.

| Command | When | Page |
|---|---|---|
| `/ruver-feature-delivery` (`/ruver-fd`) | Grill → spec → tickets → TDD → draft PR | [ruver-feature-delivery](ruver-feature-delivery.md) |
| `/ruver-code-review` | One GitHub review artifact | [ruver-code-review](ruver-code-review.md) |

## Branch helpers

| Command | When | Page |
|---|---|---|
| `/ruver-validate-branch` | Local gates before push | [ruver-validate-branch](ruver-validate-branch.md) |
| `/ruver-create-pr-frontend` | Draft an FE PR body (do not open it) | [ruver-create-pr](ruver-create-pr.md) |
| `/ruver-create-pr-backend` | Draft a BE PR body (do not open it) | [ruver-create-pr](ruver-create-pr.md) |

How they connect: [../ARCHITECTURE.md](../ARCHITECTURE.md).
Role: [../GRAPH_ENGINEER.md](../GRAPH_ENGINEER.md).
Host mapping: [../../plugins/ruver/HOST.md](../../plugins/ruver/HOST.md).
