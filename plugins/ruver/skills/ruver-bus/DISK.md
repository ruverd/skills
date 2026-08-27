# Ruver disk (global)

**Never** create `.ruver-*` at a git root, worktree, or anywhere inside a
repo. That includes `.ruver-bus/`, `.ruver-developer/`, `.ruver-qa/`,
`.ruver-triage/`, `.ruver-reviewer/`, `.ruver-lstm/`,
`.ruver-code-review/`, `.ruver-feature-delivery/`, `.ruver-goal/`,
and `.ruver/`.

## Home

```bash
slug=$(git rev-parse --show-toplevel | sed 's|^/||; s|/|-|g')
RUVER_ROOT="$HOME/.grok/ruver/$slug"
mkdir -p "$RUVER_ROOT"
```

Example: repo `/Users/ruverdornelas/Developer/empath/empath-api-v2`
→ `~/.grok/ruver/Users-ruverdornelas-Developer-empath-empath-api-v2/`.

All `.ruver-*` paths in ruver skills are **under `$RUVER_ROOT`**:

```
$RUVER_ROOT/
  .ruver-bus/
  .ruver-developer/
  .ruver-qa/
  .ruver-triage/
  .ruver-reviewer/
  .ruver-lstm/
  .ruver-code-review/
  .ruver-feature-delivery/
  .ruver-goal/
```

`.ruver-bus/ENVELOPE.md` means `$RUVER_ROOT/.ruver-bus/ENVELOPE.md`.

One slug per git toplevel (each worktree has its own). Claude and Grok
on this machine share the same files. Do **not** `git add` these dirs.

If a leftover `.ruver-*` exists inside the repo, move it into
`$RUVER_ROOT` and delete the copy in the repo. Do not keep writing there.
