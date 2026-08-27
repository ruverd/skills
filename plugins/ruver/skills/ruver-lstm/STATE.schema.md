# LSTM STATE

**Path:** `.ruver-lstm/STATE.md`

## status

```
init | resolving | rebasing | verifying | grilling | patching | replying | waiting_user | done | escalated
```

## Fields

| Field | Use |
|---|---|
| `pr_url` | target PR |
| `repo` | `owner/name` |
| `branch` | head ref |
| `sha` | head oid |
| `mergeable` | MERGEABLE / CONFLICTING / DIRTY / … |
| `ci` | green / red / pending / unknown |
| `review_ids` | comma list of review `databaseId` in this run |
| `processed_review_ids` | ids that already have 👍 + reply on **that** id |
| `dispositions` | `fix` / `skip` / `unclear` counts or path |
| `conflict_fixed` | yes / no / n/a |
| `patched` | yes / no |
| `grill` | skipped / done / waiting |
| `coder_status` | DONE / NEEDS_CONTEXT / BLOCKED |
| `job_id` | bus JOBS id (`lstm-pr-N`) |
| `lane` | `foreground` \| `worker` |
| `worktree` | path if lane=worker |
| `worker_id` | spawn id if lane=worker |
| `waiting_user` | ASK text if stopped |

Processed means: **this** GitHub review `databaseId` has author 👍 on
its body **and** a reply submitted after that review. A later re-review
(new id) that restates old findings is still **new**.
