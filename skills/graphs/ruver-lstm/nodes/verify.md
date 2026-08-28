# Node: verify

**Verb:** judge

Load skill **`receiving-code-review`**. Verify before implementing.

Fetch reviews + inline comments + issue comments
([GITHUB.md](../references/GITHUB.md)).

Skip a comment only if STATE `processed_comment_ids` already has 👍
**and** a reply on that comment. A review in `processed_review_ids`
is not enough if any of its comments are missing. A new id that
restates old F-ids is still new.

`COMMENTED` is not a skip. Medium / High / Critical in a body-only
review is feedback. Lows / nits: one-line skip verdict is enough.

For each finding, against **current HEAD**:

| Disposition | When |
|---|---|
| **fix** | Technically correct for this codebase, still reproduces |
| **skip** | Wrong, stale, YAGNI, out of scope, or already gone |
| **unclear** | Cannot verify without a fact you do not have |

Unclear + last-resort ASK → `waiting_user`, stop.
Otherwise DECIDE skip or fix and log it.

Do not implement in this node.
