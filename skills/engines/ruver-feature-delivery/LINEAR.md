# Linear via the project's MCP

Use this file only when [PRODUCT.md](PRODUCT.md) set `tracker: linear`.
**Only** the `linear-server` (or the equivalent name in this project). **No** `orca linear`.

A bare `ABC-123` with Linear MCP **offline** is a local goal, not this
hard gate. This gate fires when the user pasted a `linear.app` URL.

## Fetch

```
get_issue(id, includeRelations: true)
list_comments(issueId) → paginate to the end
get_issue on related / parent / children / blocks / blockedBy
extract_images if screenshots matter
```

## Branch

1. Issue `gitBranchName` if it exists
2. else `feature/<id-lowercase>`

Checkout before implementing. Shipper checks the branch.

## Persistence

`.ruver-feature-delivery/linear-context.md` + STATE `linear_*` fields.

If `tracker: linear` (a Linear URL) and MCP `linear-server` fails / is offline / needs auth:

1. **Do not** invent AC / description / comments.
2. **Do not** implement.
3. Emit the error in English (template in [MCP_CONTEXT.md](MCP_CONTEXT.md)):

```text
## ERROR: MCP unreachable
Could not reach Linear MCP (linear-server) for ticket <ID>.
...
```

4. `result=blocked`, `mcp_gate=failed`.
