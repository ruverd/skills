# Args: Linear ticket, goal, or resume

`$ARGUMENTS` (and the rest of the user message) must resolve to **one** of these. Do not ask which one if the text is enough.

## Parse (first, before admit)

Trim. Then, in order:

| Match | Mode |
|---|---|
| empty, and STATE exists with `status` not in `done` / `done_notes` | **resume** the current job |
| `resume` / `retomar` / `continue` (whole token, case-insensitive) | **resume** (`retomar` is a PT-BR alias) |
| Linear URL (`linear.app/...`) | **ticket** |
| issue id `[A-Z][A-Z0-9]+-\d+` | **ticket** |
| GitHub PR URL, or envelope `QA_RESULT` FAIL+`PR_BUG` | **fix** (existing PR) |
| free text with no resume, no STATE | **local goal** |
| empty, no STATE, no goal text | **stop** — ask for the ticket or the goal |

Examples:

```text
/ruver-developer DEV-1212
/ruver-developer DEV-1212: extra note
/ruver-developer https://linear.app/empathmsp/issue/DEV-1212/...
/ruver-developer null crash in MembersTable
/ruver-developer resume
/ruver-developer resume: the answer is B
```

`DEV-1212: note` → ticket `DEV-1212`, extra text is the note (and, if `waiting_user`, it is also the answer).

## Resume

Load, in order:

1. `$RUVER_ROOT/.ruver-developer/STATE.md`
2. `$RUVER_ROOT/.ruver-feature-delivery/STATE.md` (if present)
3. `$RUVER_ROOT/.ruver-feature-delivery/HANDOFF.md` (if present)
4. `$RUVER_ROOT/.ruver-bus/STACK.md` + `ENVELOPE.md`

**Reconcile** with git/gh before skipping nodes:

- branch exists and is checked out (or the worktree path in STATE)
- `pr_url` still points at that branch, if set
- delivery `status` vs files on disk (SPEC.md, TICKETS.md)

Then continue at `next_node` / current graph status. Do **not**:

- re-fetch Linear as a blank start
- re-grill settled `## Decisions`
- skip an open ASK; the current user message **is** the answer
- restart delivery if `fd_status=done` (go **mergeable** / QA instead)

No STATE / no HANDOFF → tell the user in Brazilian Portuguese that there is nothing to resume.

## After a waiting_user stop

The next invocation is resume, even if the user types the ticket id again. Attach their message as the ASK answer, then continue.
