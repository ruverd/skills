# `/ruver-memory`

Alias: **`/memory`**. Durable prefs **outside git**. Not a graph.
Does not walk STATE. Does not open a PR.

Skill: [`../../skills/ruver-memory`](../../skills/ruver-memory).
Disk: [`../../skills/ruver-bus/DISK.md`](../../skills/ruver-bus/DISK.md).

## When

- `/memory` — show `$RUVER_HOME/memory.md` and `$RUVER_ROOT/memory.md`
- `/memory me responder em PT-BR` — home `## Chat`
- `/memory --project reviewers: alice, bob` — this repo's confirmed reviewers
- A ruver graph starts (admit / fd / code-review) — **read**, do not wait

Reviewer fallback when `AGENTS.md` and `CODEOWNERS` are empty:
[PRODUCT.md](../../skills/ruver-feature-delivery/PRODUCT.md) §6.
Ship requests. `/reviewer` does not.

## Never

- Write these files inside a repo
- Translate GitHub/GitLab text because chat is PT-BR
- Block CI to ask an Open question

## Related

[`/ruver-developer`](ruver-developer.md) ·
[PRODUCT.md](../../skills/ruver-feature-delivery/PRODUCT.md)
