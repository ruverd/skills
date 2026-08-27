# GitHub (LSTM)

One home for fetch / 👍 / reply / resolve / re-request.

## Fetch

```bash
gh pr view "$PR" --repo "$REPO" --json number,url,isDraft,state,mergeable,mergeStateStatus,headRefOid,baseRefName,headRefName,reviewDecision,statusCheckRollup

gh api "repos/$REPO/pulls/$PR/reviews" --paginate
gh api "repos/$REPO/pulls/$PR/comments" --paginate
gh api "repos/$REPO/issues/$PR/comments" --paginate
```

URL fragments: `#pullrequestreview-<id>` · `#discussion_r<id>` ·
`#issuecomment-<id>`.

## Reactions (analyzed, not "fixed")

```bash
gh api -X POST "repos/$REPO/pulls/comments/$COMMENT_ID/reactions" \
  -f content='+1'

gh api -X POST "repos/$REPO/pulls/$PR/reviews/$REVIEW_ID/reactions" \
  -f content='+1'
```

Never put 👍 in the reply body.

## Reply

Unslop first. Load bundled `unslop` on the body, then POST. English.

Inline thread:

```bash
gh api "repos/$REPO/pulls/$PR/comments/$COMMENT_ID/replies" \
  -f body="$BODY"
```

Body-only review (no inline): COMMENT review on the PR after that
review. Nested reply on `pullrequestreview-*` 404s.

## Resolve thread (fix landed)

Need the GraphQL thread id:

```bash
gh api graphql -f query='
query($o:String!,$n:String!,$p:Int!) {
  repository(owner:$o, name:$n) {
    pullRequest(number:$p) {
      reviewThreads(first: 100) {
        nodes { id isResolved
          comments(first: 20) { nodes { databaseId } } }
      }
    }
  }
}' -F o=OWNER -F n=REPO -F p=$PR
```

```bash
gh api graphql -f query='
mutation($id:ID!) {
  resolveReviewThread(input: {threadId: $id}) {
    thread { isResolved }
  }
}' -F id="$THREAD_ID"
```

## Re-request (fix landed)

```bash
gh api -X POST "repos/$REPO/pulls/$PR/requested_reviewers" \
  -f "reviewers[]=$LOGIN"
```
