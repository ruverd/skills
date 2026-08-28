#!/usr/bin/env python3
"""Every relative markdown link must resolve. Prose links only: fenced code
blocks and inline code spans hold illustrative paths, not real ones."""
import os
import re
import sys

LINK = re.compile(r'\[[^\]]*\]\(([^)\s]+)(?:\s+"[^"]*")?\)')
SKIP_PREFIX = ("http://", "https://", "mailto:", "#", "tel:")
PRUNE = {".git", ".worktrees", "node_modules"}


def strip_inline_code(line: str) -> str:
    return re.sub(r'`[^`]*`', "", line)


def md_files(root: str):
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames if d not in PRUNE]
        for name in sorted(filenames):
            if name.endswith(".md"):
                yield os.path.join(dirpath, name)


def skill_root_of(rel: str):
    """The skill directory a file belongs to, or None for an index page."""
    parts = rel.split(os.sep)
    if len(parts) >= 3 and parts[0] == "skills":
        return os.sep.join(parts[:2])
    return None


def escaping(root: str):
    """After install every skill is a flat sibling directory under one skills
    root. A sibling hop (../other-skill/FILE.md) resolves identically in git and
    on disk. A link that leaves the skills root does not: it only works on hosts
    that walk symlinks with the kernel, and breaks on hosts that normalise the
    path string first."""
    out = []
    for path in md_files(root):
        rel = os.path.relpath(path, root)
        if skill_root_of(rel) is None:
            continue
        fenced = False
        with open(path, encoding="utf-8") as handle:
            for lineno, raw in enumerate(handle, 1):
                if raw.lstrip().startswith("```"):
                    fenced = not fenced
                    continue
                if fenced:
                    continue
                for target in LINK.findall(strip_inline_code(raw)):
                    if target.startswith(SKIP_PREFIX):
                        continue
                    target = target.split("#", 1)[0]
                    if not target:
                        continue
                    resolved = os.path.relpath(
                        os.path.normpath(os.path.join(os.path.dirname(path), target)),
                        root,
                    )
                    if resolved != "skills" and not resolved.startswith("skills" + os.sep):
                        out.append((rel, lineno, target))
    return out


def broken(root: str):
    out = []
    for path in md_files(root):
        fenced = False
        with open(path, encoding="utf-8") as handle:
            for lineno, raw in enumerate(handle, 1):
                if raw.lstrip().startswith("```"):
                    fenced = not fenced
                    continue
                if fenced:
                    continue
                for target in LINK.findall(strip_inline_code(raw)):
                    if target.startswith(SKIP_PREFIX):
                        continue
                    target = target.split("#", 1)[0]
                    if not target:
                        continue
                    if target.startswith(("/", "~")):
                        out.append((path, lineno, target, "absolute or home path"))
                        continue
                    resolved = os.path.normpath(
                        os.path.join(os.path.dirname(path), target)
                    )
                    if not os.path.exists(resolved):
                        out.append((path, lineno, target, "missing"))
    return out


def main() -> int:
    root = sys.argv[1] if len(sys.argv) > 1 else "."
    found = broken(root)
    for path, lineno, target, why in found:
        print(f"{os.path.relpath(path, root)}:{lineno}: {why}: {target}")
    leaks = escaping(root)
    for rel, lineno, target in leaks:
        print(f"{rel}:{lineno}: link leaves its own skill directory: {target}")
    if found or leaks:
        print(f"{len(found)} broken, {len(leaks)} escaping", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
