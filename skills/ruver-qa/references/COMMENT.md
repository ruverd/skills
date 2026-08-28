# QA PR comment (mandatory)

After a **final** verdict (`PASS` / `FAIL` / `BLOCKED`), post **one**
GitHub comment on the PR. This is not optional.

Never comment `PENDING_TRIAGE`.

## Collect evidence first

QA execute must have recorded:

- Playwright **video** (`--video=on` on the run)
- Screenshots of the AC paths
- command + exit + failing names if any

Paths live under `test-results/**` (or the repo's configured output).

## Publish video

GitHub comments cannot play a local `.webm`. Upload, then link.

**Never** `gh gist create` on `.webm` / `.mp4` / `.png`. gh 2.58+
returns `binary file not supported`. Secret is already the default
(`--secret` is gone).

Run the skill script (text gist, then `git push` of the media):

```bash
../scripts/publish-evidence.sh \
  --repo "$REPO" --pr "$PR" --sha "$SHA" \
  --video "$VIDEO" --artifacts .ruver-qa/artifacts
```

Use the printed `GIST_URL` / `VIDEO_MP4` / `SCREENSHOT=` lines in the
comment. Embed PNGs as `![label](raw-url)`.

GitHub comments **do not inline-play** gist video (only
`user-attachments` does). Link the gist + raw mp4/webm. Do not commit
videos to the PR branch.

If the script exits 2, still comment with the printed `LOCAL_VIDEO`
path — do **not** skip the comment.

## Post

```bash
gh pr comment "$PR" --repo "$REPO" --body-file "$BODY"
```

`$BODY` template (English — it is GitHub):

```markdown
## QA: PASS

| | |
|---|---|
| PR | <url> |
| SHA | `<sha>` |
| Surface | <routes / endpoints / specs from PLAN.md> |
| Plan | <step count> steps |
| Findings | <n or none> |
| Triage | <class or n/a> |
| Tracker | <NEW_BUG ids or n/a> |

<summary of the plan + what passed>

### Evidence
- Video: <gist url>
- Screenshots: <gist or raw urls>

<!-- ruver-qa: v=1 verdict=PASS sha=<sha> -->
```

Headers: `## QA: PASS` · `## QA: FAIL` · `## QA: BLOCKED`.

`FAIL` includes expected vs actual + triage class.
`BLOCKED` includes what was missing (env/auth/app).

One comment per SHA. If a comment with the same
`ruver-qa: v=1 … sha=<sha>` already exists, do not post another.

## Hard rules

- No verdict without this comment.
- No comment without attempting a video upload when a `.webm` exists.
- **PASS requires evidence.** UI: video of the route. API-only: HTTP
  record of the changed endpoints (video if captured). If capture
  failed on a UI run, say so in the comment and do **not** treat
  the run as a complete PASS.
- Do not commit videos to the PR branch.
- Do not paste credentials or raw `.env`.
