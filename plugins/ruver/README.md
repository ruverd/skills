# Ruver plugin

Skills, agents, and slash-command aliases for the Ruver graphs.

Start here: [../../README.md](../../README.md)

| Command | Role | Page |
|---|---|---|
| `/ruver-developer` | Deliver a ticket. Draft PR. Hand off to QA. | [docs](../../docs/commands/ruver-developer.md) |
| `/ruver-reviewer` | Review a PR. Diagnose CI. | [docs](../../docs/commands/ruver-reviewer.md) |
| `/ruver-lstm` | Incoming review comments. Patch the same branch. | [docs](../../docs/commands/ruver-lstm.md) |
| `/ruver-qa` | Exercise the PR in a browser. Comment with video. | [docs](../../docs/commands/ruver-qa.md) |
| `/ruver-triage` | Classify a QA finding. | [docs](../../docs/commands/ruver-triage.md) |
| `/ruver-bus` | Resume the graph stack. | [docs](../../docs/commands/ruver-bus.md) |
| `/ruver-goal` | Wake until QA+video. | [docs](../../docs/commands/ruver-goal.md) |
| `/ruver-fd` | Delivery engine (CI green). | [docs](../../docs/commands/ruver-feature-delivery.md) |
| `/ruver-code-review` | One GitHub review artifact. | [docs](../../docs/commands/ruver-code-review.md) |

All pages: [docs/commands](../../docs/commands/README.md).

State files live in `~/.ruver/<slug>/`, never in a git repo.
Harness mapping: [HOST.md](HOST.md). Role: [docs/GRAPH_ENGINEER.md](../../docs/GRAPH_ENGINEER.md).
