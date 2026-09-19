#!/usr/bin/env bash
set -euo pipefail

if [[ -n "${GODOT:-}" ]]; then
	GODOT="$GODOT"
elif [[ -x "$HOME/.local/opt/godot" ]]; then
	GODOT="$HOME/.local/opt/godot"
elif command -v godot4 >/dev/null 2>&1; then
	GODOT="$(command -v godot4)"
elif command -v godot >/dev/null 2>&1; then
	GODOT="$(command -v godot)"
else
	printf 'FAIL: set GODOT or install a godot4/godot executable\n' >&2
	exit 1
fi
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
PROJECT="$(cd -- "$SCRIPT_DIR/.." && pwd -P)"
LOG_DIR="${TMPDIR:-/tmp}/royal-forest-verify"
ERROR_PATTERN='SCRIPT ERROR|Parse Error|ERROR:'
mkdir -p "$LOG_DIR"

inspect_log() {
	local label="$1" log_file="$2"
	if grep -Eq "$ERROR_PATTERN" "$log_file"; then
		printf 'FAIL: %s emitted a Godot error; see %s\n' "$label" "$log_file" >&2
		exit 1
	fi
}

run_checked() {
	local label="$1" log_file="$2" expected_token="$3"
	shift 3
	printf '\n== %s ==\n' "$label"
	"$@" 2>&1 | tee "$log_file"
	inspect_log "$label" "$log_file"
	if [[ -n "$expected_token" ]] && ! grep -Fq "$expected_token" "$log_file"; then
		printf 'FAIL: %s missing token %q\n' "$label" "$expected_token" >&2
		exit 1
	fi
}

printf 'Godot: %s (%s)\n' "$GODOT" "$("$GODOT" --version)"
printf '\n== documentation consistency ==\n'
"$SCRIPT_DIR/docs_consistency.sh" --self-test
"$SCRIPT_DIR/docs_consistency.sh"
printf '\n== mutation-sensitive negative gates ==\n'
GODOT="$GODOT" "$SCRIPT_DIR/negative_gates.sh"
run_checked "import" "$LOG_DIR/import.log" "" "$GODOT" --headless --path "$PROJECT" --import
run_checked "test runner" "$LOG_DIR/tests.log" "RESULT: PASS" "$GODOT" --headless --path "$PROJECT" res://tests/test_runner.tscn
run_checked "enemy tracking scenario" "$LOG_DIR/enemy-tracking.log" "TRACKING RESULT: PASS" "$GODOT" --headless --path "$PROJECT" res://tests/probes/enemy_tracking_probe.tscn
run_checked "real-display mouse input" "$LOG_DIR/mouse-input.log" "PASS: test_game_root.test_mouse_motion_yaws_player_with_hud_present" xvfb-run -a "$GODOT" --path "$PROJECT" res://tests/test_runner.tscn
rm -rf "${TMPDIR:-/tmp}/royal-forest-recording-probe"
run_checked "24 FPS diagnostic recording" "$LOG_DIR/recording.log" "RECORDING PROBE: PASS" xvfb-run -a "$GODOT" --path "$PROJECT" res://tests/probes/gameplay_recording_probe.tscn
run_checked "M1 combat smoke" "$LOG_DIR/combat-smoke.log" "SMOKE RESULT: OK" "$GODOT" --headless --path "$PROJECT" res://tests/smoke/combat_smoke.tscn
run_checked "legacy prototype smoke" "$LOG_DIR/legacy-smoke.log" "SMOKE RESULT: OK" "$GODOT" --headless --path "$PROJECT" res://tools/smoke_test.tscn

printf '\n== bounded main-scene boot ==\n'
set +e
timeout --kill-after=5s 12s "$GODOT" --headless --path "$PROJECT" 2>&1 | tee "$LOG_DIR/boot.log"
boot_status=${PIPESTATUS[0]}
set -e
if [[ $boot_status -ne 0 && $boot_status -ne 124 ]]; then
	exit "$boot_status"
fi
inspect_log "bounded main-scene boot" "$LOG_DIR/boot.log"
printf 'PASS: bounded main-scene boot (exit %d)\n' "$boot_status"

printf '\n== real-framebuffer visual probe ==\n'
GODOT="$GODOT" "$SCRIPT_DIR/run_visual_probe.sh" 2>&1 | tee "$LOG_DIR/visual.log"
grep -Fxq "VISUAL PROBE: PASS (13 captures in $PROJECT/artifacts/visual)" "$LOG_DIR/visual.log"
grep -Fxq 'VISUAL CAPTURE SET: m1-neutral.png,m1-low-stamina.png,m1-enemy-tell.png,m1-enemy-active.png,m1-attack-windup.png,m1-attack-active.png,m1-attack-recovery.png,m1-hit-confirm.png,m1-guarding.png,m1-blocked.png,m1-guard-break.png,m1-death.png,m2-crouched-behind-low-cover.png' "$LOG_DIR/visual.log"
grep -Fxq 'VISUAL CAPTURES: neutral, low-stamina, enemy-tell, enemy-active, attack-windup, attack-active, attack-recovery, hit-confirm, guarding, blocked, guard-break, death, crouched-behind-low-cover' "$LOG_DIR/visual.log"

printf '\n== whitespace check ==\n'
git -C "$PROJECT" diff --check
git -C "$PROJECT" diff --check HEAD
printf 'PASS: diff --check\n'
printf '\nVERIFY RESULT: PASS\nLogs: %s\n' "$LOG_DIR"
