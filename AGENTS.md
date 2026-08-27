# ai-skills

Marketplace of Ruver agent skills. Not an application repo.

- Canonical files live under `plugins/ruver/`.
- Skills must stay siblings so relative links like `../ruver-bus/PROTOCOL.md` resolve.
- Do not write `.ruver-*` state in this repo. Runtime state belongs in `~/.ruver/<slug>/`.
- Graphs are host-agnostic. Harness APIs live in `plugins/ruver/HOST.md`. See `docs/GRAPH_ENGINEER.md`.
- After a skill edit, run `./install.sh` if you use the symlink install. Plugin installs pick up git updates with `grok plugin update ruver`.
- User-facing chat in the graphs is Brazilian Portuguese. Skill bodies stay in English.
