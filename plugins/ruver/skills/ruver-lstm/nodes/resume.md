# Node: resume

**Verb:** continue

Load `.ruver-lstm/STATE.md`. Reconcile `pr_url` / `sha` with `gh pr view`.
If `waiting_user`, the current message is the answer. Then jump to
`status` (verifying / patching / replying / rebasing). Do not re-ack
ids already in `processed_review_ids`.
