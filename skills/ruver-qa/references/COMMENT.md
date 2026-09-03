# QA PR comment (mandatory)

After a **final** verdict (`PASS` / `FAIL` / `BLOCKED`), post **one**
GitHub comment on the PR. This is not optional.

Never comment `PENDING_TRIAGE`.

## Collect evidence first

QA execute must have recorded:

- agent-browser **video** (`record start` / `record stop`)
- Screenshots of the AC paths
- command + exit + failing names if any

Paths live under `$CAPTURE_DIR` or `.ruver-qa/artifacts`.

Stills before/after belong on the **PR body**
([before-and-after](../../before-and-after/SKILL.md)), not in this
comment.

## Post (video on the comment)

GitHub comments play `user-attachments` video. They do not play
gist `.webm`. **Never** `gh gist create` on media.

Write `$BODY`. Replace `VIDEO_PATH` with the recorded `.webm` so
`gh --attach` can rewrite it. Then:

```bash
../scripts/publish-evidence.sh \
  --repo "$REPO" --pr "$PR" --sha "$SHA" \
  --body-file "$BODY" \
  --video "$VIDEO" --artifacts .ruver-qa/artifacts
```

The script runs `gh pr comment --attach`. Use the printed
`COMMENT_URL`. `gh` ≥ 2.99.

If the script exits 2, still get a comment up with the printed
`LOCAL_VIDEO` path — do **not** skip the comment.

## Body

`$BODY` template (English — it is GitHub):

```markdown
## QA: PASS

| | |
|---|---|
| PR | <url> |
| SHA | `<sha>` |
| Surface | <routes / endpoints from PLAN.md> |
| Plan | <step count> steps |
| Findings | <n or none> |
| Triage | <class or n/a> |
| Tracker | <NEW_BUG ids or n/a> |

<summary of the plan + what passed>

### Evidence
[Walk video](VIDEO_PATH)

<!-- ruver-qa: v=1 verdict=PASS sha=<sha> -->
```

Headers: `## QA: PASS` · `## QA: FAIL` · `## QA: BLOCKED`.

`FAIL` includes expected vs actual + triage class.
`BLOCKED` includes what was missing (env/auth/app/agent-browser).

One comment per SHA. If a comment with the same
`ruver-qa: v=1 … sha=<sha>` already exists, do not post another.

## Hard rules

- No verdict without this comment.
- No comment without attempting `--attach` when a `.webm` exists.
- **PASS requires evidence.** UI: video of the route. API-only: HTTP
  record of the changed endpoints. If capture failed on a UI run,
  say so in the comment and do **not** treat the run as a complete
  PASS.
- Do not commit videos to the PR branch.
- Do not paste credentials or raw `.env`.
