#!/usr/bin/env python3
"""Minimal frontmatter reader. pyyaml is not guaranteed on a runner, and the
subset used here is key: value plus folded > and | blocks."""
import os
import re

PRUNE = {".git", ".worktrees", "node_modules"}


def parse(path):
    """Return (fields, keys_in_order) or (None, None) when there is no frontmatter."""
    with open(path, encoding="utf-8") as handle:
        text = handle.read()
    match = re.match(r"^---\n(.*?)\n---(?:\n|$)", text, re.S)
    if not match:
        return None, None
    fields = {}
    order = []
    key = None
    for raw in match.group(1).split("\n"):
        if raw[:1] in (" ", "\t"):
            if key is not None:
                fields[key] = (fields[key] + " " + raw.strip()).strip()
            continue
        if not raw.strip():
            continue
        if ":" not in raw:
            continue
        name, _, value = raw.partition(":")
        key = name.strip()
        value = value.strip()
        if value in (">", "|", ">-", "|-"):
            value = ""
        fields[key] = value
        order.append(key)
    return fields, order


def skill_files(root):
    base = os.path.join(root, "skills")
    for dirpath, dirnames, filenames in os.walk(base):
        dirnames[:] = [d for d in dirnames if d not in PRUNE]
        if "SKILL.md" in filenames:
            yield os.path.join(dirpath, "SKILL.md")


def flat_files(root, kind):
    base = os.path.join(root, kind)
    if not os.path.isdir(base):
        return
    for name in sorted(os.listdir(base)):
        if name.endswith(".md"):
            yield os.path.join(base, name)
