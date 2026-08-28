# CI + mergeability gates

Do not treat "CI is green" as enough. Both must be true:

```text
CI = fully green
AND
mergeability = MERGEABLE
```

## Check

```bash
gh pr view "$PR" --repo "$REPO" \
  --json url,isDraft,mergeable,mergeStateStatus,statusCheckRollup,headRefOid,headRefName

gh pr checks "$PR" --repo "$REPO" --json name,bucket,state,workflow,link
```

Follow `ruver-feature-delivery` `CI_DELIVERY.md` for the poll/fix loop.
Never use `gh pr checks --watch` as the only wait (tool timeout < CI).

## CI green

No **required** check in fail / pending / cancelled-as-fail.
If GitHub does not expose required, treat every attached check as required.

## MERGEABLE

`mergeable == MERGEABLE` (or `mergeStateStatus == CLEAN`).

Not ready: `CONFLICTING`, `DIRTY`, `BLOCKED`, `UNKNOWN`, pending.

Conflicts on this branch → merge/rebase base when safe, push, re-check CI.
Do not force-push unless the repo already uses it and it is safe.

## Draft

Draft + MERGEABLE + green CI is the **ready-for-QA** state. Do not mark
Ready before QA.

After `QA_RESULT` **PASS** (apply_qa): mark **Ready for Review**

```bash
gh pr ready "$PR" --repo "$REPO"
```

Never merge. Ready ≠ merge.
