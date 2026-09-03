#!/usr/bin/env python3
"""Every relative markdown link must resolve. Fenced blocks stay
illustrative. Inline code that looks like a skill path must exist, and
the pre-flatten layout (skills/graphs|engines|lib/) is always a fail."""
import os
import re
import sys

LINK = re.compile(r'\[[^\]]*\]\(([^)\s]+)(?:\s+"[^"]*")?\)')
INLINE = re.compile(r"`([^`]*)`")
STALE_LAYOUT = re.compile(r"(?:\.\./)*skills/(graphs|engines|lib)/")
SKILL_PATH = re.compile(r"(?:\.\./)*skills/[a-z0-9-]+/.+")
SKIP_PREFIX = ("http://", "https://", "mailto:", "#", "tel:")
PRUNE = {".git", ".worktrees", "node_modules"}


def strip_inline_code(line: str) -> str:
    return INLINE.sub("", line)


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


def unfenced_lines(path: str):
    fenced = False
    with open(path, encoding="utf-8") as handle:
        for lineno, raw in enumerate(handle, 1):
            if raw.lstrip().startswith("```"):
                fenced = not fenced
                continue
            if not fenced:
                yield lineno, raw


def link_targets(raw: str):
    for target in LINK.findall(strip_inline_code(raw)):
        if target.startswith(SKIP_PREFIX):
            continue
        target = target.split("#", 1)[0]
        if target:
            yield target


def exists_as_skill_path(root: str, path: str, span: str) -> bool:
    here = os.path.normpath(os.path.join(os.path.dirname(path), span))
    there = os.path.normpath(os.path.join(root, span))
    return os.path.exists(here) or os.path.exists(there)


def code_span_issue(root: str, path: str, span: str):
    if STALE_LAYOUT.search(span):
        return "stale layout"
    if "<" in span or "*" in span or not SKILL_PATH.search(span):
        return None
    if not exists_as_skill_path(root, path, span):
        return "missing"
    return None


def leaves_skills_root(root: str, path: str, target: str) -> bool:
    resolved = os.path.relpath(
        os.path.normpath(os.path.join(os.path.dirname(path), target)),
        root,
    )
    return resolved != "skills" and not resolved.startswith("skills" + os.sep)


def scan(root: str):
    broken, leaks, codes = [], [], []
    for path in md_files(root):
        rel = os.path.relpath(path, root)
        skill = skill_root_of(rel)
        for lineno, raw in unfenced_lines(path):
            for target in link_targets(raw):
                if target.startswith(("/", "~")):
                    broken.append((path, lineno, target, "absolute or home path"))
                else:
                    resolved = os.path.normpath(
                        os.path.join(os.path.dirname(path), target)
                    )
                    if not os.path.exists(resolved):
                        broken.append((path, lineno, target, "missing"))
                if skill is not None and leaves_skills_root(root, path, target):
                    leaks.append((rel, lineno, target))
            for span in INLINE.findall(raw):
                why = code_span_issue(root, path, span)
                if why:
                    codes.append((path, lineno, span, why))
    return broken, leaks, codes


def main() -> int:
    root = sys.argv[1] if len(sys.argv) > 1 else "."
    found, leaks, codes = scan(root)
    for path, lineno, target, why in found:
        print(f"{os.path.relpath(path, root)}:{lineno}: {why}: {target}")
    for rel, lineno, target in leaks:
        print(f"{rel}:{lineno}: link leaves its own skill directory: {target}")
    for path, lineno, target, why in codes:
        print(f"{os.path.relpath(path, root)}:{lineno}: {why}: {target}")
    if found or leaks or codes:
        print(
            f"{len(found)} broken, {len(leaks)} escaping, {len(codes)} code",
            file=sys.stderr,
        )
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
