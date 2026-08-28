# Node: request_triage

**Verb:** switch  
Envelope `TRIAGE_REQUEST` using [../references/HANDOFF.md](../references/HANDOFF.md).
Attach every `## F<n>` from `.ruver-qa/FINDINGS.md` (or `payload_path`
if huge). PR link required.

STATE: `status=triage_requested`, `qa=PENDING_TRIAGE`,
`findings_path=.ruver-qa/FINDINGS.md`.

Bus switch to `triage`. Do not spawn `ruver_triage`.
Do not post a PR comment yet.
