# Adapter: Cursor

Maps [HOST.md](../../ruver-host/SKILL.md) primitives. Graphs stay generic.

| Primitive | Cursor |
|---|---|
| `load_skill` / `load_graph` | `/ruver-<name>` |
| `spawn_worker` | `Task` general-purpose |
| `schedule_wake` | ask the user to re-run unless a loop command exists |
| `session_model` | inherit |

Install drops skills in `~/.cursor/skills`.
Disk: `$HOME/.ruver/<slug>`.
