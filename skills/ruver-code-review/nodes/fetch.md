# 4. Fetch — pass dependent

```bash
gh pr checks "$PR" --repo "$REPO"        # only for the failing/pending check names
```

**Deep** — full PR diff plus whole changed files:

```bash
gh pr diff "$PR" --repo "$REPO"
```

Then `Read` each changed file in full, highest churn first, up to the cap.

**Light** — incremental diff only:

```bash
gh api "repos/$REPO/compare/$OLD_SHA...$HEAD_SHA" \
  --jq '.files[] | {filename, status, additions, deletions, patch}'
```

`404` or missing SHA (force-push, rebase) → fall back to the full `gh pr diff`,
note `stale_base` in the chat summary, and treat the pass as light anyway.

### 4.1 Carry-forward — light pass only

Every entry in the prior marker's `open=` list must be resolved before this run can
publish. Reads here are **outside** the light file cap, bounded by the 10-entry list.

| Entry | Action |
|---|---|
| its file appears in the incremental diff | re-verify against the new code |
| its file is untouched | `Read` that file at the head SHA and re-verify |
| still reproduces | re-publish it, same severity, suffixed `carried from <sha7>` |
| no longer reproduces | drop it in silence |
| its file was deleted, or the code it pointed at is gone | drop it in silence |

An author reply, a comment, or a pushed commit is **not** evidence that a carried
finding was fixed. Only the code at the head SHA is. A run that cannot re-verify an
entry (file unreadable, cap exhausted) treats it as unresolved and keeps it.
