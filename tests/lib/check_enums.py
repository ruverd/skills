#!/usr/bin/env python3
"""One enum, one meaning, per graph.

A graph spreads the same field across GRAPH.md, ROUTING.md and STATE.schema.md.
Nothing kept them in step, so `scope` grew a fourth value in the schema that
ROUTING.md never learned, and `route_confidence` was declared in ROUTING.md
without ever reaching the schema at all. Both are the kind of drift a reader
resolves silently and wrongly.
"""
import os
import re
import sys

from frontmatter import parse, skill_files

# `field: a | b | c` on its own line, inside a yaml block or not. Indentation is
# captured because a nested `status:` under `ci:` is not the graph's own
# `status`, and conflating them reports drift that is not there.
YAML_ENUM = re.compile(r"^(\s*)-?\s*([a-z][a-z0-9_]*):\s*([a-z][a-z0-9_]*(?:\s*\|\s*[a-z][a-z0-9_]*)+)\s*$")
# `- **field:** a | b | c` — how templates/STATE.md spells the same enum.
BULLET_ENUM = re.compile(r"^-\s+\*\*([a-z][a-z0-9_.]*):\*\*\s*([a-z][a-z0-9_]*(?:\s*\|\s*[a-z][a-z0-9_]*)+)\s*$")
# Any `key:` line, enum or not — nesting context for the rule above.
YAML_KEY = re.compile(r"^(\s*)-?\s*([a-z][a-z0-9_]*):")
# `| `field` | a \| b \| c |` — a markdown table row, pipes escaped.
TABLE_ENUM = re.compile(r"^\|\s*`([a-z][a-z0-9_]*)`\s*\|\s*([a-z][a-z0-9_]*(?:\s*\\\|\s*[a-z][a-z0-9_]*)+)")
# Enums that are host or forge vocabulary, not state this graph owns.
EXEMPT = {"from", "to"}


def values(raw):
    return frozenset(part.strip() for part in raw.replace("\\|", "|").split("|"))


# STATE.schema.md also declares an enum as a `## field` heading over a fenced
# block of pipe-separated values. Read that form too, or the schema looks silent
# about the fields it actually owns.
HEADING = re.compile(r"^##\s+`?([a-z][a-z0-9_]*)`?\s*$")


def heading_enums(path):
    """`## field` over a fenced block of pipe-separated values, wrapped or not."""
    found = {}
    field = None
    buffer = None
    fence_line = 0
    with open(path, encoding="utf-8") as handle:
        for lineno, line in enumerate(handle, 1):
            if line.startswith("```"):
                if buffer is None:
                    buffer, fence_line = [], lineno + 1
                    continue
                blob = " ".join(buffer)
                buffer = None
                parts = [part.strip() for part in blob.split("|")]
                if field and len(parts) > 1 and all(
                    re.fullmatch(r"[a-z][a-z0-9_]*", part) for part in parts
                ):
                    found.setdefault(field, []).append((frozenset(parts), fence_line))
                field = None
                continue
            if buffer is not None:
                buffer.append(line.strip())
                continue
            match = HEADING.match(line)
            if match:
                field = match.group(1)
                continue
            span = line.strip()
            if field and span.startswith("`") and span.endswith("`") and "|" in span:
                parts = [part.strip() for part in span.strip("`").split("|")]
                if all(re.fullmatch(r"[a-z][a-z0-9_]*", part) for part in parts):
                    found.setdefault(field, []).append((frozenset(parts), lineno))
                    field = None
    return found


def declarations(path):
    """field -> [(values, lineno)] for every enum this file declares."""
    found = {}
    stack = []  # (indent, key) for the enclosing yaml mapping
    fenced = False

    def record(field, raw, lineno):
        found.setdefault(field, []).append((values(raw), lineno))

    with open(path, encoding="utf-8") as handle:
        for lineno, line in enumerate(handle, 1):
            if line.startswith("```"):
                fenced = not fenced
                stack = []
                continue

            bullet = BULLET_ENUM.match(line)
            if bullet:
                record(bullet.group(1), bullet.group(2), lineno)
                continue

            table = TABLE_ENUM.match(line)
            if table:
                record(table.group(1), table.group(2), lineno)
                continue

            key = YAML_KEY.match(line)
            if not key:
                continue
            indent, name = len(key.group(1)), key.group(2)
            if fenced:
                while stack and stack[-1][0] >= indent:
                    stack.pop()

            enum = YAML_ENUM.match(line)
            if enum:
                qualified = ".".join([k for _, k in stack] + [name]) if fenced else name
                if qualified.split(".")[-1] not in EXEMPT:
                    record(qualified, enum.group(3), lineno)
            elif fenced:
                stack.append((indent, name))

    return found


def main():
    root = sys.argv[1] if len(sys.argv) > 1 else "."
    errors = []

    for skill in skill_files(root):
        fields, _ = parse(skill)
        if not fields or fields.get("category") not in ("graph", "engine"):
            continue
        directory = os.path.dirname(skill)
        name = os.path.basename(directory)
        schema = os.path.join(directory, "STATE.schema.md")
        if not os.path.exists(schema):
            continue

        seen = {}
        candidates = [
            entry for entry in sorted(os.listdir(directory)) if entry.endswith(".md")
        ]
        if os.path.exists(os.path.join(directory, "templates", "STATE.md")):
            candidates.append(os.path.join("templates", "STATE.md"))
        for entry in candidates:
            path = os.path.join(directory, entry)
            if not os.path.isfile(path):
                continue
            found = declarations(path)
            if entry == "STATE.schema.md":
                for field, hits in heading_enums(path).items():
                    found.setdefault(field, []).extend(hits)
            for field, hits in found.items():
                for value_set, lineno in hits:
                    seen.setdefault(field, []).append((entry, lineno, value_set))

        for field, hits in sorted(seen.items()):
            if len({value_set for _, _, value_set in hits}) == 1:
                continue
            where = "; ".join(
                f"{entry}:{lineno} = {' | '.join(sorted(value_set))}"
                for entry, lineno, value_set in hits
            )
            errors.append(f"{name}: {field} declared with different values — {where}")

    for line in errors:
        print(line)
    if errors:
        print(f"{len(errors)} enum problem(s)", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
