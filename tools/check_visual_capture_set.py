#!/usr/bin/env python3
"""Fail unless a visual artifact directory contains exactly the expected entries."""

from pathlib import Path
import sys


def main() -> int:
    if len(sys.argv) < 3:
        print("usage: check_visual_capture_set.py OUTPUT_DIR EXPECTED...", file=sys.stderr)
        return 2
    output_dir = Path(sys.argv[1])
    expected = sorted(sys.argv[2:])
    actual = sorted(path.name for path in output_dir.iterdir()) if output_dir.is_dir() else []
    if actual != expected:
        print(
            f"M2B1_VISUAL_SET_EXACT: expected={expected} actual={actual}",
            file=sys.stderr,
        )
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
