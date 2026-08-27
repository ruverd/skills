# TDD

pstack `tdd` + this iron law. **No production code before a failing test** on a **confirmed seam**.

pstack tdd may say "skip when the path is expensive". **Ignore that skip** on a behavior change. Write the failing test or upgrade the path (DECIDE). Do not ASK to skip TDD.

## Iron law

```
NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST
```

Production code before the failing test → delete it and start over. Do not "adapt" it. Do not "use it as reference".

## Seams

A seam is the public boundary you observe. Use case, HTTP route, hook, screen behavior. Not a private helper.

Before the first test of a ticket, pick the seam from the table (DECIDE, log). If two seams could work, pick the outer public one. Do not ASK.

Empath defaults:

| Change | Default seam |
|---|---|
| API service / use case | co-located `file.test.ts` |
| HTTP contract | controller test + TypeBox schema |
| Prisma / tenant | repository test |
| UI behavior | co-located `Component.test.tsx` |
| Bug | failing test that reproduces the bug |

`it('should ...')`. Tests live next to the code when the repo already does that.

## Loop

1. RED. Write the test. Run it. Watch it fail for the right reason.
2. GREEN. Minimum code to pass.
3. Re-run that test. Then the local file.
4. Next slice. Refactor after review, not inside the red-green loop.

## Anti-patterns

- Tests that mirror implementation
- Tautological expects
- All tests first, then all code (horizontal slice)
- Mocking the thing under test
- Skipping RED because "it is simple"
- "I will test later" / "I already tested by hand"

## Evidence

Coder returns:

```text
tdd_behaviors: N
red: <command> → fail <name>
green: <command> → pass
files_changed: [...]
```

Parent writes `## TDD evidence` in STATE. Reviewer **fails** the ticket if evidence is missing. Prose does not replace the exit code in `.ruver-feature-delivery/gates.log`.

## What may skip TDD

Only with an explicit log in Decisions, and only:

- Throwaway prototype (grill)
- Generated config
- Pure CSS with no behavior

## Playwright / E2E

Only if done criteria needs an end-to-end UI flow. Unit/integration first. E2E does not replace TDD of logic.
