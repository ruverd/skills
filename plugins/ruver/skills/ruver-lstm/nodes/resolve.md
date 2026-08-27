# Node: resolve

**Verb:** inspect

Never guess repo. Parse ARGS into `{REPO, PR, review_ids, comment_ids}`.
See [GITHUB.md](../references/GITHUB.md) for URL fragments.

```bash
gh pr view "$PR" --repo "$REPO" --json number,url,title,isDraft,state,mergeable,mergeStateStatus,headRefOid,baseRefName,headRefName,reviewDecision,statusCheckRollup
```

Write `pr_url`, `repo`, `branch`, `sha`, `mergeable`, `ci`.
Extract Linear `DEV-\d+` from branch or title when present.

CLOSED / MERGED → stop, chat only.

Then **conflict** if `DIRTY` / `CONFLICTING`, else **verify**.
