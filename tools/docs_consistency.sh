#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
PROJECT="$(cd -- "$SCRIPT_DIR/.." && pwd -P)"

python3 - "$PROJECT" "${1:-}" <<'PY'
from pathlib import Path
import re
import sys

root = Path(sys.argv[1])
mode = sys.argv[2]
canonical = (
    "Green pursuit and recovery re-aim rapidly (540°/s); orange windup permits only "
    "slow limited turning (45°/s); only the red active strike is direction-committed (0°/s)."
)
allowed_population = "M2e populates route-facing narrative content"
m1_patterns = [
    re.compile(r"\bm1\b[^\n]{0,80}(verdict|gate)[^\n]{0,60}(pending|awaiting)", re.IGNORECASE),
    re.compile(r"(verdict|gate)[^\n]{0,60}\bm1\b[^\n]{0,60}(pending|awaiting)", re.IGNORECASE),
    re.compile(r"(pending|awaiting)[^\n]{0,80}\bm1\b[^\n]{0,60}(verdict|gate)", re.IGNORECASE),
]
narrative_patterns = [
    re.compile(r"\bm2e\b[^\n]{0,120}(creates?|adds?|introduces?|owns?)[^\n]{0,80}\bNarrativeState\b", re.IGNORECASE),
    re.compile(r"\bNarrativeState\b[^\n]{0,120}(introduced|created|added|owned)[^\n]{0,40}(in|during|at)\s+\bM2e\b", re.IGNORECASE),
]


def contradictory_claims(text: str) -> list[str]:
    failures: list[str] = []
    lowered = text.lower()
    for stale in ("still required", "remains blocked"):
        if stale in lowered:
            failures.append(f"contains stale phrase: {stale}")
    if any(pattern.search(text) for pattern in m1_patterns):
        failures.append("contains stale M1 verdict-pending language")
    if any(pattern.search(text) for pattern in narrative_patterns):
        failures.append("assigns NarrativeState creation to M2e")
    return failures


def run_self_test() -> None:
    reject_cases = {
        "m1-forward": "M1 verdict remains pending.",
        "m1-reverse": "The verdict for M1 remains pending.",
        "m1-pending-first": "Pending: the M1 human gate.",
        "narrative-forward": "M2e introduces NarrativeState.",
        "narrative-reverse": "NarrativeState is introduced in M2e.",
    }
    for name, text in reject_cases.items():
        if not contradictory_claims(text):
            raise SystemExit(f"SELF-TEST FAIL: accepted contradictory fixture {name}: {text}")
    accept_cases = {
        "accepted-m1": "The M1 verdict was recorded on 2026-09-18.",
        "allowed-population": allowed_population + "; it does not introduce a new persistence owner here.",
        "m2c-owner": "M2c creates WorldState and NarrativeState before route production.",
    }
    for name, text in accept_cases.items():
        failures = contradictory_claims(text)
        if failures:
            raise SystemExit(f"SELF-TEST FAIL: rejected allowed fixture {name}: {failures}")
    print("DOCS CONSISTENCY SELF-TEST: PASS")


if mode == "--self-test":
    run_self_test()
    raise SystemExit(0)
if mode:
    raise SystemExit(f"unknown argument: {mode}")

expected = [
    root / "README.md",
    root / "docs/GAME_DESIGN_DOCUMENT.md",
    root / "docs/plans/REQUIREMENTS.md",
    root / "docs/plans/REBUILD_PLAN.md",
    root / "playtest/m1/README.md",
]
failures: list[str] = []
texts: list[str] = []
for path in expected:
    text = path.read_text(encoding="utf-8")
    texts.append(text)
    for failure in contradictory_claims(text):
        failures.append(f"{path.relative_to(root)} {failure}")
    if canonical not in text:
        failures.append(f"{path.relative_to(root)} is missing the canonical 540/45/0 turning sentence")

ownership_docs = "\n".join(texts)
if allowed_population not in ownership_docs:
    failures.append("documentation must preserve the allowed M2e narrative-content wording")

if failures:
    for failure in failures:
        print(f"FAIL: {failure}", file=sys.stderr)
    raise SystemExit(1)
print("DOCS CONSISTENCY: PASS")
PY
