# Host contract

Graphs name **primitives**. This file maps them onto the harness in
front of you. If a node mentions a primitive, do that mapping here.
Do not copy harness APIs into GRAPH.md.

In this repo, skills live under `skills/{graphs,engines,lib}/`.
After install they flatten to siblings (`ruver-qa` next to `ruver-bus`
and `unslop`).
Resolve a skill **by name** via the host skill loader, or by the
relative path in git. Never hardcode `~/.agents/skills`, `~/.grok`,
`~/.claude`, or `~/.codex`.

## Primitives

| Primitive | Meaning | Fallback if the host has no API |
|---|---|---|
| `load_skill name` | Inject that skill's SKILL.md (and GRAPH.md if present) into **this** thread | Read the flattened sibling, or `skills/<category>/<name>/SKILL.md` in git |
| `load_graph name` | Same as `load_skill ruver-<name>`. Main thread only | Same |
| `spawn_worker` | One child session, **general-purpose**. Not a graph name | Tell the user the worker prompt; or run the node inline if isolation is impossible |
| `worktree` | Isolated checkout of the same branch | `git worktree add` (JOBS.md) |
| `schedule_wake` | Resume this graph later without blocking the turn | Ask the user to re-run the slash command when CI moves; do not `gh pr checks --watch` |
| `cancel_wake` | Drop that scheduled resume | No-op if none exists |
| `session_model` | Whatever the current session already uses | Do not pin `grok-*` / `sonnet` / `opus` in graph files |

## spawn_worker

Pass: job id, worktree path (or “host worktree”), the **node file**
as the contract, “do not spawn graph types”, never merge.

Prefer host isolation `worktree` when the spawn API has it. Then do
**not** also pass `cwd`.

| Host | Call |
|---|---|
| Grok | `spawn_subagent` `subagent_type: general-purpose` `isolation: "worktree"` |
| Claude Code | `Agent` / `Task` with `general-purpose` (or the fd agent name for implement/test/review) |
| Codex | child agent spawn; isolation if the CLI exposes a worktree |
| Cursor | `Task` general-purpose |

Never `spawn_worker` with types `ruver_developer` / `ruver_qa` /
`ruver_triage` / `ruver_reviewer` / `ruver_lstm`. Those are
`load_graph` on the main thread.

Fd **workers** (`ruver-fd-coder`, `ruver-fd-tester`, …) may be the
child type when the host registered them. If it did not, use
general-purpose and paste the node file into the prompt.

## schedule_wake

Used by `ruver-goal` and `ruver-code-review` wait_ci. Interval 5m.
One wake per PR. Store the host's id in STATE as `loop_id`.

| Host | Call |
|---|---|
| Grok | `scheduler_create` (same as `/loop`). Delete with `scheduler_delete` |
| Claude Code | `/loop` or the scheduler the session already uses. Else ask the user to re-run |
| Codex | host wakeup if present; else ask the user to re-run |
| Cursor | same fallback |

The wake prompt is in the skill's `LOOP.md`. It must `load_skill` by
**name**, not by an absolute home path.

## Slash / invoke

| Host | How the user starts a graph |
|---|---|
| Grok | `/developer` (command alias) or `/ruver-developer` (skill name) |
| Claude Code | `/developer` or `/ruver-developer` |
| Codex | `$ruver-developer` or the skill menu |
| Cursor | `/ruver-developer` |

Short command aliases (Grok / Claude, via `commands/`): `/developer`,
`/reviewer`, `/lstm`, `/qa`. Same skill. Skill folder names stay
`ruver-*`.

## Disk

`$RUVER_ROOT` is host-neutral. See [skills/graphs/ruver-bus/DISK.md](skills/graphs/ruver-bus/DISK.md).
Claude, Codex, Grok, and Cursor on one machine **share** that tree.

## Quality rubric

`ruver-fd-quality` loads bundled
`thermo-nuclear-code-quality-review` (`skills/lib/`). Always run
`fix all`. Do not skip.

## Product policy

Reviewers, assignee, sibling repos, test command, tracker, design
system: [PRODUCT.md](skills/engines/ruver-feature-delivery/PRODUCT.md)
plus the **current repo** (`AGENTS.md`, `CLAUDE.md`, `CONTRIBUTING`).
Do not bake a company's GitHub handles or repo names into a graph node.
