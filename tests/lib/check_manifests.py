#!/usr/bin/env python3
"""Manifests must agree with each other and with the tree on disk."""
import json
import os
import sys

from frontmatter import flat_files, skill_files

# Files carrying the plugin version. .grok-plugin/plugin-index.json is excluded
# on purpose: its "version" is a schema version, not the plugin version.
VERSIONED = [
    ("plugin.json", ("version",)),
    (".claude-plugin/plugin.json", ("version",)),
    (".claude-plugin/marketplace.json", ("plugins", 0, "version")),
    (".grok-plugin/marketplace.json", ("plugins", 0, "version")),
]
# Manifests that enumerate skill paths and must list every skill.
SKILL_LISTS = ["plugin.json", ".claude-plugin/plugin.json"]
INDEX = ".grok-plugin/plugin-index.json"


def dig(blob, path):
    for key in path:
        blob = blob[key]
    return blob


def load(root, rel):
    with open(os.path.join(root, rel), encoding="utf-8") as handle:
        return json.load(handle)


def main():
    root = sys.argv[1] if len(sys.argv) > 1 else "."
    errors = []

    skill_dirs = {}
    for path in skill_files(root):
        directory = os.path.dirname(path)
        name = os.path.basename(directory)
        skill_dirs[name] = "./" + os.path.relpath(directory, root)

    versions = {}
    for rel, path in VERSIONED:
        try:
            versions[rel] = dig(load(root, rel), path)
        except (KeyError, IndexError, FileNotFoundError) as exc:
            errors.append(f"{rel}: cannot read version ({exc})")
    if len(set(versions.values())) > 1:
        listed = ", ".join(f"{k}={v}" for k, v in sorted(versions.items()))
        errors.append(f"plugin version disagrees across manifests: {listed}")

    for rel in SKILL_LISTS:
        listed = set(load(root, rel).get("skills", []))
        for name, wanted in sorted(skill_dirs.items()):
            if wanted not in listed:
                errors.append(f"{rel}: skill not listed: {wanted}")
        for extra in sorted(listed - set(skill_dirs.values())):
            errors.append(f"{rel}: listed path is not a skill directory: {extra}")

    index = load(root, INDEX)
    components = index["plugins"]["ruver"]["components"]
    for kind, wanted in (
        ("skills", set(skill_dirs)),
        ("agents", {os.path.basename(p)[:-3] for p in flat_files(root, "agents")}),
        ("commands", {os.path.basename(p)[:-3] for p in flat_files(root, "commands")}),
    ):
        have = {entry["name"] for entry in components.get(kind, [])}
        for missing in sorted(wanted - have):
            errors.append(f"{INDEX}: {kind} missing: {missing}")
        for stale in sorted(have - wanted):
            errors.append(f"{INDEX}: {kind} lists something absent from the tree: {stale}")

    for line in errors:
        print(line)
    if errors:
        print(f"{len(errors)} manifest problem(s)", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
