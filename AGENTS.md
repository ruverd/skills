# skills

Marketplace of Ruver agent skills. Not an application repo.

- Canonical skill files live under `skills/{graphs,engines,branch,lib}/`.
- `skills/lib/` is the bundled primitives (`unslop`, `grill-with-docs`, `receiving-code-review`, `principle-*`, …). Graphs must load those, not an external marketplace.
- Graphs in the same category stay siblings (`../ruver-bus/PROTOCOL.md`).
- Cross-category links use `../../engines/...` / `../../graphs/...`.
- After `install.sh`, skills flatten into `~/.agents/skills/<name>` so slash names stay flat.
- Short command aliases (`/developer`, `/reviewer`, `/lstm`, `/qa`) live in `commands/`. Skill ids stay `ruver-*`.
- Do not write `.ruver-*` state in this repo. Runtime state belongs in `~/.ruver/<slug>/`.
- Graphs are host-agnostic. Harness APIs live in `HOST.md`. See `docs/GRAPH_ENGINEER.md`.
- After a skill edit, run `./install.sh` if you use the symlink install. Plugin installs pick up git updates with `grok plugin update ruver`.
- User-facing chat in the graphs is Brazilian Portuguese. Skill bodies stay in English.
