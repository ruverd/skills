# Adapter: Codex

Maps [HOST.md](../../../../HOST.md) primitives. Graphs stay generic.

| Primitive | Codex |
|---|---|
| `load_skill` / `load_graph` | `$ruver-<name>` or the skills menu |
| `spawn_worker` | child agent, general-purpose; worktree if the CLI exposes it |
| `schedule_wake` | host wakeup if present; else ask the user to re-run |
| `cancel_wake` | drop that wakeup |
| `session_model` | inherit |

Install drops skills in `~/.codex/skills` and `~/.agents/skills`.
Disk: `$HOME/.ruver/<slug>`.
