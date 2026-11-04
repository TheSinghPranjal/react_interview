#!/usr/bin/env python3
"""Fail if the worktree is dirty after the version-bump commit.

`flutter pub get` may rewrite pubspec.lock, and newer Flutter SDKs may also
rewrite analysis_options.yaml. Those files are ignored. Any other dirty or
untracked path fails the job.

This is the check that failed the first real Undercover production run when
it treated pub-get output as an unexpected change.
"""

from __future__ import annotations

import subprocess
import sys

# Exact repo-relative paths. Do not ignore directories or other generated files.
PUB_GET_OUTPUT = frozenset(
    {
        "pubspec.lock",
        "analysis_options.yaml",
    }
)


def fail(message: str) -> None:
    print(f"error: {message}", file=sys.stderr)
    raise SystemExit(1)


def status_entries(blob: bytes) -> list[tuple[str, list[str]]]:
    """Parse `git status --porcelain=v1 -z` into (status, paths) entries."""
    parts = blob.split(b"\0")
    entries: list[tuple[str, list[str]]] = []
    index = 0
    while index < len(parts):
        record = parts[index]
        index += 1
        if record == b"":
            continue
        if len(record) < 4 or record[2:3] != b" ":
            fail(f"unexpected git status record: {record!r}")
        status = record[:2].decode()
        paths = [record[3:].decode()]
        if "R" in status or "C" in status:
            if index >= len(parts) or parts[index] == b"":
                fail("git status rename/copy record is missing its original path")
            paths.append(parts[index].decode())
            index += 1
        entries.append((status, paths))
    return entries


def unexpected_entries(
    entries: list[tuple[str, list[str]]],
) -> tuple[list[tuple[str, list[str]]], list[str]]:
    bad: list[tuple[str, list[str]]] = []
    ignored: list[str] = []
    for status, paths in entries:
        extra = [path for path in paths if path not in PUB_GET_OUTPUT]
        if extra:
            bad.append((status, paths))
        else:
            ignored.extend(paths)
    return bad, ignored


def main() -> None:
    blob = subprocess.check_output(
        ["git", "status", "--porcelain=v1", "-z", "--untracked-files=all"]
    )
    bad, ignored = unexpected_entries(status_entries(blob))
    if bad:
        lines = [
            "worktree is dirty after the version bump "
            "(only pubspec.lock and analysis_options.yaml may remain from flutter pub get):"
        ]
        for status, paths in bad:
            lines.append(f"  {status} {' -> '.join(paths)}")
        fail("\n".join(lines))
    if ignored:
        print(
            "Clean-tree check passed. Ignored flutter pub get output: "
            + ", ".join(ignored)
        )
    else:
        print("Clean-tree check passed. No flutter pub get output left dirty.")


if __name__ == "__main__":
    main()
