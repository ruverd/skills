# Node: apply_qa

**Verb:** route  
**Capability:** read envelope, write STATE

Read `QA_RESULT`. Follow the GRAPH apply_qa edges.
Write `qa_verdict` and any Linear ids from the envelope notes.
`PENDING_TRIAGE` → stay put. `PASS` with `NEW_BUG` → cite tickets,
do not pad this PR.

On **`QA_RESULT` PASS** (including PASS + NEW_BUG / EXISTING_BUG /
NOT_A_BUG when this PR's ACs still hold): mark the PR Ready for
Review — `gh pr ready "$PR" --repo "$REPO"`. Confirm `isDraft=false`.
Still **never merge**.

Do not invent product behavior on ambiguity → escalate.
Do not dequeue the next QA here — `verdict` does that after
this node returns.
