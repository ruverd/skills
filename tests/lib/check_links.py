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
    if found:
        print(f"{len(found)} broken link(s)", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
