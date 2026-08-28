#!/usr/bin/env python3
"""Files and directories a published repo is expected to carry."""
import os
import sys

REQUIRED = [
    "CONTRIBUTING.md",
    "CHANGELOG.md",
    "SECURITY.md",
    "CODEOWNERS",
    ".github/PULL_REQUEST_TEMPLATE.md",
    ".github/ISSUE_TEMPLATE/bug_report.md",
    ".github/ISSUE_TEMPLATE/feature_request.md",
]
# Internal working notes do not belong on every user's disk.
FORBIDDEN = ["docs/superpowers"]


def main():
    root = sys.argv[1] if len(sys.argv) > 1 else "."
    errors = []
    for rel in REQUIRED:
        if not os.path.exists(os.path.join(root, rel)):
            errors.append(f"missing: {rel}")
    for rel in FORBIDDEN:
        if os.path.exists(os.path.join(root, rel)):
            errors.append(f"should not be published: {rel}")
    for line in errors:
        print(line)
    if errors:
        print(f"{len(errors)} structure problem(s)", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
