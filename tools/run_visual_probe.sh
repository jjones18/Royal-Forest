#!/usr/bin/env bash
set -euo pipefail
GODOT="${GODOT:-$HOME/.local/opt/godot}"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
PROJECT="$(cd -- "$SCRIPT_DIR/.." && pwd -P)"
OUTPUT_DIR="$PROJECT/artifacts/visual"
LOG="${TMPDIR:-/tmp}/royal-forest-visual.log"
EXPECTED=(
	m1-neutral.png m1-low-stamina.png m1-enemy-tell.png m1-enemy-active.png
	m1-attack-windup.png m1-attack-active.png m1-attack-recovery.png m1-hit-confirm.png
	m1-guarding.png m1-blocked.png m1-guard-break.png m1-death.png
	m2-crouched-behind-low-cover.png
)
rm -rf -- "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"
xvfb-run -a -s "-screen 0 1280x720x24" env LIBGL_ALWAYS_SOFTWARE=1 \
	"$GODOT" --path "$PROJECT" --resolution 1280x720 res://tests/visual/screenshot_probe.tscn 2>&1 | tee "$LOG"
if grep -Eq 'SCRIPT ERROR|Parse Error|ERROR:' "$LOG"; then
	printf 'FAIL: visual probe emitted a Godot error\n' >&2
	exit 1
fi
grep -Fq 'VISUAL RESULT: OK' "$LOG"
for image in "${EXPECTED[@]}"; do
	test -s "$OUTPUT_DIR/$image"
done
python3 "$SCRIPT_DIR/check_visual_capture_set.py" "$OUTPUT_DIR" "${EXPECTED[@]}"
printf 'VISUAL CAPTURE SET: %s\n' "$(IFS=,; printf '%s' "${EXPECTED[*]}")"
printf 'VISUAL PROBE: PASS (%d captures in %s)\n' "${#EXPECTED[@]}" "$OUTPUT_DIR"
