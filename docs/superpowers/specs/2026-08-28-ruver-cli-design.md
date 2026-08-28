# Ruver CLI (install + update)

Date: 2026-08-28
Status: approved in chat, pending implementation
Baseline: `origin/main` @ `726f67e` (includes `ruver-memory`)

Turn `install.sh` into a bash CLI that installs and updates Ruver skills
without Node or Bun. Same job as today's symlink flatten, plus a durable
`ruver` on PATH and `ruver update`. UX modeled on empath-api-v2
`bun run db:local` (banner, menu, `--yes`, `--dry-run`), not on
Superpowers' per-host plugin install.

## Decisions (locked)

| Choice | Value |
|---|---|
| Command on PATH | `ruver` |
| Skill files | Managed git clone + symlink flatten |
| First-run | `curl …/install.sh \| bash` (no TTY, implied `setup --yes`) |
| Windows | Git Bash or WSL. No PowerShell script |
| Plugin | Not invoked. `plugin.json` stays for people who use marketplaces |
| Update channel | `git pull --ff-only` of `main`. Version display = `plugin.json` + short SHA |
| Shape | One file: `install.sh` is bootstrap and CLI. `~/.local/bin/ruver` is a symlink into that file in the clone |

Rejected: tarball copy, per-host plugin wrap, two-script bootstrap/CLI split,
native PowerShell, git tags as the update pin.

## Compatibility with `726f67e` (`ruver-memory`)

`install.sh` on main did not change. Flatten still picks up any
`skills/{graphs,engines,lib}/*/SKILL.md` and every file under `agents/`
and `commands/`. New paths ride that loop:

- `skills/lib/ruver-memory/` → `~/.agents/skills/ruver-memory` (and the other homes)
- `commands/memory.md`, `commands/ruver-memory.md` → `~/.grok/commands`, `~/.claude/commands`

Do **not** special-case those names.

Runtime disk (`skills/graphs/ruver-bus/DISK.md`):

```
$RUVER_HOME/                # default ~/.ruver
  memory.md                 # you. ruver-memory. Create on write, not on install
  <slug>/
    memory.md               # this git toplevel. same rule
    .ruver-developer/
    …
```

Installer rules that follow:

1. `setup` may `mkdir -p "$HOME/.ruver"` (or the existing
   `~/.ruver` → `~/.grok/ruver` link). It must **not** create `memory.md`.
   Missing file means empty. The skill owns creation.
2. `uninstall` and `--purge` never delete `$HOME/.ruver`, `memory.md`,
   or `$RUVER_ROOT`. Graphs and chat language survive uninstall.
3. Tests must assert a planted `~/.ruver/memory.md` is still there after
   uninstall and after `--purge`.

Chat language lives in home `memory.md`, not in this CLI. The CLI's
own strings stay English (it is repo-facing, like forge text).

## Layout

| What | Path |
|---|---|
| Managed clone | `${XDG_DATA_HOME:-$HOME/.local/share}/ruver/repo` |
| Pointer | `${XDG_CONFIG_HOME:-$HOME/.config}/ruver/config` |
| Command | `$HOME/.local/bin/ruver` → `<repo>/install.sh` |
| Skills | today's five homes, flattened |
| Graph + memory | `$HOME/.ruver/` (untouched except mkdir / legacy link) |
| Backup of colliding dests | `$HOME/.skills-backups/<timestamp>/` (existing) |

Config is `KEY=value` lines (bash 3.2). Required key: `repo=`. Optional:
`origin=` (default `https://github.com/ruverd/skills.git`).

`$HOME/.ruver` is **not** installer state. Do not put the clone or the
pointer there.

### Resolve the script path

Today `REPO="$(cd "$(dirname "$0")" && pwd)"`. That breaks when `$0` is
the PATH symlink (`~/.local/bin`). Resolve symlinks before `cd`
(macOS has no `readlink -f`). After resolve, `REPO` is the directory
that contains `install.sh` and `plugin.json`.

`is_ours` compares `readlink` of the dest to `"$REPO/"*`. Use the
canonical repo path so a PATH-symlink invocation still owns the links
it created.

## Entry modes

**Bootstrap (pipe).** `curl -fsSL https://raw.githubusercontent.com/ruverd/skills/main/install.sh | bash`

Detect: the running script is not a regular file sitting next to
`plugin.json`. Then:

1. Need `git` and `curl`. Else exit 1 with the install command.
2. If config already points at a git work tree whose `plugin.json`
   has `"name": "ruver"`, skip clone.
3. Else `git clone --branch main` into the managed path (https URL, so
   SSH keys are not required).
4. Write config. Symlink `~/.local/bin/ruver`. If this is the first
   clone, `exec` that clone's `install.sh setup --yes`. If a clone
   already existed, `exec` `update` then `setup --yes` (ff-only, then
   relink).

Second curl on a machine that already has Ruver is that last branch.
Idempotent.

stdin is the script. Never prompt. Never raw-mode.

**Checkout.** `./install.sh` or `./install.sh setup` inside a clone
writes `repo=` to that checkout (for example `~/Developer/skills`).
Does not copy into the managed path. `--purge` later must refuse this
path.

**PATH.** `ruver <cmd>` is the same file via symlink.

## Commands

Flags work before or after the subcommand (`ruver --yes setup`,
`ruver setup --yes`). Global: `--dry-run`, `--yes` / `-y`, `-h` / `--help`.

| Invocation | Behavior |
|---|---|
| `ruver` + TTY, no args | Arrow menu: setup, update, status, uninstall |
| `ruver` without TTY, no args | Static list + examples, exit 0 (db:local non-TTY) |
| `ruver setup` | Flatten + bin + PATH snippet + config |
| `ruver update` | `git fetch` + `git pull --ff-only origin main` + setup relink |
| `ruver status` | repo, version, SHA, ahead/behind, PATH, per-home ok/missing/not ours, plugin warning |
| `ruver uninstall` | Remove our symlinks only |
| `ruver uninstall --purge` | Then delete the **managed** clone and config. Confirm unless `--yes` |
| `ruver --help` | Usage + examples (see below) |
| `ruver setup --help` (and each subcommand) | That command's flags + examples |
| `./install.sh --uninstall` | Alias of `uninstall` (compat) |
| `./install.sh --plugin` | Print `grok plugin install ruver --trust` / Claude equivalent. Do not install. Exit 1 |

`--dry-run` prints `dry-run: …` and writes nothing.

### setup

Idempotent. Same flatten as main today:

- `skills/{graphs,engines,lib}/*` with `SKILL.md` →
  `~/.agents/skills`, `~/.grok/skills`, `~/.claude/skills`,
  `~/.cursor/skills`, `~/.codex/skills`
- `agents/` → `~/.grok/agents`, `~/.claude/agents`
- `commands/` → `~/.grok/commands`, `~/.claude/commands`

Always those five skill homes (mkdir -p). No host picker.

If dest exists and is not our symlink: move to
`~/.skills-backups/<timestamp>/`, then link. If the move fails, stop.

Ensure `~/.local/bin/ruver` → this `install.sh`.

If `~/.local/bin` is not on PATH, append a marked block once to
`~/.zshrc` and `~/.bashrc`. Marker: `# ruver PATH`. Skip if that
comment is already in the file. Last line of setup also prints the
export so a current shell can pick it up.

### update

Read config. Abort if `repo` is not a git work tree, if `git status`
is dirty, or if the merge is not a fast-forward. Print
`<plugin.json version> <oldsha> → <version> <newsha>`. Then the same
relink as setup.

Dirty tree: print `git status -sb` and
`commit or stash, then ruver update`. Exit 1.

### status

Plugin Grok/Claude `ruver` also installed: warning, exit 0. Setup does
not uninstall the plugin.

### uninstall

`is_ours` only. Foreign dest: `keep`. Remove PATH symlink if it points
at this `install.sh`. Do not strip the PATH block from rc files (leave
the directory on PATH).

`--purge` deletes `${XDG_DATA_HOME:-$HOME/.local/share}/ruver/repo`
only when `repo=` equals that path. A checkout pointer (Developer tree)
→ exit 1, "this is your development clone".

## Menu and output

TTY: short RUVER banner (not the Empath art), dim one-liner, arrow
picker (↑/↓/j/k, enter, q). Ctrl-C restores cooked mode + cursor, exit
130.

`NO_COLOR` set or stdout not a TTY: no ANSI.

Success lines stay parseable: `ok`, `link`, `relink`, `backup`, `rm`,
`keep`, plus `version:` / `sha:` on update.

## Errors

| Case | Exit | Next step in the message |
|---|---|---|
| Missing `git` / `curl` on bootstrap | 1 | The curl one-liner |
| Clone fails | 1 | git stderr. Do not delete an older clone |
| Dirty update | 1 | `ruver update` after stash |
| Diverged clone | 1 | `ruver status` |
| Backup move fails | 1 | path |
| `--purge` of a non-managed repo | 1 | nothing |
| Unknown command | 1 | `ruver --help` |
| `--plugin` | 1 | host plugin install line |

## `--help` examples

Root:

```
Examples:
  curl -fsSL https://raw.githubusercontent.com/ruverd/skills/main/install.sh | bash
  ruver setup
  ruver update
  ruver status
  ruver uninstall
```

`update --help`:

```
Examples:
  ruver update
  ruver update --dry-run
```

## Tests

No Node. `tests/install.sh` drives `install.sh` with a temp `HOME`.
CI: macOS (bash 3.2) and Ubuntu. Not Windows.

1. `--help` / unknown command (0 / 1)
2. `--dry-run setup` prints, writes nothing
3. setup against a fixture clone (plugin.json + one lib skill with
   SKILL.md): dest symlink, `~/.local/bin/ruver` points at fixture
   `install.sh`, config written
4. setup again: `ok`, no new backup
5. dirty `update`: exit 1
6. clean `update`: two-commit local git, SHA changes, links still valid
7. uninstall: our links gone; foreign dest kept; planted
   `~/.ruver/memory.md` kept
8. `--purge`: deletes managed clone only; refuses a checkout pointer;
   `memory.md` still kept
9. no TTY: no-args prints the list, does not enter raw mode

Do not call `grok plugin`. Flatten test does not name `ruver-memory`;
the category loop is the contract.

## Docs to change in the same PR

- `README.md` Installation: curl one-liner first. Then `ruver update` /
  `status`. Clone path as "developing this repo". Plugin as a footnote.
- `AGENTS.md`: `ruver setup` / `ruver update` instead of only
  `./install.sh`. Keep the plugin update sentence for marketplace users.
- `docs/GRAPH_ENGINEER.md`: same.
- `install.sh` header comment: the new usage.

## Out of scope

- Git tags / versioned releases
- `install.ps1`
- Auto `grok plugin install` / `claude plugins install`
- Creating `memory.md`
- Changing flatten targets or adding Cursor/Codex command homes
- A second binary
