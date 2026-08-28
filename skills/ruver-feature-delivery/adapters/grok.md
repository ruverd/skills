# Adapter: Grok

Maps [HOST.md](../../ruver-host/SKILL.md) primitives. Graphs stay generic.

| Primitive | Grok |
|---|---|
| `load_skill` / `load_graph` | `/ruver-<name>` or `/skills ruver-<name>` |
| `spawn_worker` | `spawn_subagent` `subagent_type: general-purpose` `isolation: "worktree"` |
| fd workers | plugin agents `ruver-fd-coder` etc. if installed |
| `schedule_wake` | `scheduler_create` (same as `/loop`) |
| `cancel_wake` | `scheduler_delete` |
| `session_model` | inherit |

Disk: `$HOME/.ruver/<slug>` (install.sh may symlink from `~/.grok/ruver`).
