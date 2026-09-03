# Node: evidence

**Verb:** capture
**Capability:** write screenshots, gist URLs, and a PR-body fragment. No product fix. No PR.
**Does not** open the PR. Shipper inlines the fragment.

## Mission

After every ticket has passed tester, before blast (`full_feature` /
`debug_fix`) or before quality (`light_change`). Capture After. Write a
fragment the shipper pastes into [../templates/PR_BODY.md](../templates/PR_BODY.md).

## When

Tester pass, no tickets left. Then this node. Then blast, or quality on
`light_change`. GRAPH.md owns the edges.

## Before capture

This node owns the rule. Neighbors get one sentence, not a copy.

- After the worktree exists, before the first RED, when a UI route
  already exists. [JOBS.md](../../ruver-bus/JOBS.md) §Worktree points here.
- `debug_fix`: capture during diagnose, while the bug still shows.
  [diagnose.md](diagnose.md) points here.
- New screen, no route yet: `Before: n/a (new screen)`.

Record route and viewport in STATE. After must reuse both.

## After capture

Same route and viewport as Before. New screen: After only.

If the PR SHA later changes, recapture After and refresh the open PR
body (`gh pr edit --body`). Developer `fix` and LSTM `patch` point here.

## How

**UI.** `qa_tool=playwright` in STATE: Playwright PNG of the route.
Anything else: host browser PNG. Same viewport as Before.

**Non-UI.** A fenced command-output pair. No invented screen.

Save PNGs under `$RUVER_ROOT/.ruver-feature-delivery/evidence/`
(`before.png` / `after.png`, or `n/a`).

## Publish

One home: [publish-evidence.sh](../../ruver-qa/scripts/publish-evidence.sh).
No new skill.

```bash
../../ruver-qa/scripts/publish-evidence.sh \
  --repo "$REPO" --pr "$PR" --sha "$SHA" \
  --screenshot "$BEFORE_PNG" --screenshot "$AFTER_PNG"
```

`--screenshot` is repeatable. Keep `--video`, `--artifacts`, `--repo`,
`--pr`, `--sha`. Secret gist.

No PR yet: keep the PNGs on disk. Shipper runs the same script after
the PR exists and replaces local paths with gist raw URLs.

## Fragment

Write `$RUVER_ROOT/.ruver-feature-delivery/pr-body-evidence.md`.

Fill **How tested** (commands + exit codes from `gates.log`) and
**Before → After** (gist raw URLs, fenced output, or `n/a`). Each claim
needs one of those three. Shipper inlines the fragment into
[../templates/PR_BODY.md](../templates/PR_BODY.md).

## Output

```text
result: ok | skipped
before: <gist raw URL | n/a (new screen) | n/a>
after: <gist raw URL | fenced | n/a>
route: <path or n/a>
viewport: <WxH or n/a>
fragment: .ruver-feature-delivery/pr-body-evidence.md
summary: ...
```

`skipped` only when there is no UI route and no command worth fencing
(docs-only). Still write the fragment with `n/a`.

## Hard rules

- Do not invent a pass. Missing After on a UI change is a fail.
- Do not open, merge, or push the PR.
- Do not change product code.
- Do not retype `gates.log` exit codes from memory.
