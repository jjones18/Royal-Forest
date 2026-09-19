#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
PROJECT="$(cd -- "$SCRIPT_DIR/.." && pwd -P)"
SELF="$SCRIPT_DIR/testing_menu.sh"
RECORDINGS_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/godot/app_userdata/Royal Forest/recordings"
EXPORTS_DIR="$HOME/aiworkspace/exports"

find_godot() {
	if [[ -n "${GODOT:-}" ]]; then
		if command -v "$GODOT" >/dev/null 2>&1; then
			command -v "$GODOT"
		elif [[ -x "$GODOT" ]]; then
			printf '%s\n' "$GODOT"
		else
			return 1
		fi
	elif [[ -x "$HOME/.local/opt/godot" ]]; then
		printf '%s\n' "$HOME/.local/opt/godot"
	elif command -v godot4 >/dev/null 2>&1; then
		command -v godot4
	elif command -v godot >/dev/null 2>&1; then
		command -v godot
	else
		return 1
	fi
}

show_error() {
	if command -v kdialog >/dev/null 2>&1; then
		kdialog --error "$1" --title "Royal Forest Testing"
	else
		printf 'ERROR: %s\n' "$1" >&2
	fi
}

play_game() {
	local godot
	if ! godot="$(find_godot)"; then
		show_error "Godot was not found. Expected ~/.local/opt/godot, godot4/godot on PATH, or a GODOT environment override."
		exit 1
	fi
	exec "$godot" --path "$PROJECT" res://game/app/game_root.tscn
}

run_tests() {
	if command -v konsole >/dev/null 2>&1; then
		exec konsole --hold -e "$SELF" --tests-inline
	elif command -v xterm >/dev/null 2>&1; then
		exec xterm -hold -e "$SELF" --tests-inline
	else
		exec "$SELF" --tests-inline
	fi
}

run_tests_inline() {
	cd "$PROJECT"
	printf 'Royal Forest — complete automated verification\n\n'
	set +e
	./tools/verify.sh
	local status=$?
	set -e
	printf '\n'
	if [[ $status -eq 0 ]]; then
		printf 'ALL TESTS PASSED\n'
	else
		printf 'TESTS FAILED (exit %d)\nLogs: /tmp/royal-forest-verify\n' "$status"
	fi
	return "$status"
}

open_path() {
	local path="$1"
	if command -v kioclient6 >/dev/null 2>&1; then
		exec kioclient6 exec "$path"
	elif command -v kioclient5 >/dev/null 2>&1; then
		exec kioclient5 exec "$path"
	elif command -v xdg-open >/dev/null 2>&1; then
		exec xdg-open "$path"
	else
		show_error "No desktop file opener was found. Open: $path"
		exit 1
	fi
}

open_guide() {
	open_path "$PROJECT/playtest/m1/README.md"
}

current_build_label() {
	local branch commit
	branch="$(git -C "$PROJECT" branch --show-current 2>/dev/null || true)"
	commit="$(git -C "$PROJECT" rev-parse --short HEAD 2>/dev/null || true)"
	if [[ -n "$branch" && -n "$commit" ]]; then
		printf '%s @ %s' "$branch" "$commit"
	else
		printf 'unversioned checkout'
	fi
}

open_recordings() {
	mkdir -p "$RECORDINGS_DIR"
	open_path "$RECORDINGS_DIR"
}

recording_files() {
	[[ -d "$RECORDINGS_DIR" ]] || return 0
	find "$RECORDINGS_DIR" -maxdepth 1 \
		\( -type f \( -name 'rf-*.mp4' -o -name 'rf-*.jsonl' -o -name 'rf-*.video.log' -o -name 'latest.txt' \) \
		-o -type d -name '.frames-rf-*' \) \
		-print0 | sort -z
}

delete_recordings() {
	local -a files=()
	while IFS= read -r -d '' path; do files+=("$path"); done < <(recording_files)
	if (( ${#files[@]} == 0 )); then
		if command -v kdialog >/dev/null 2>&1; then
			kdialog --msgbox "There are no diagnostic recordings to delete." --title "Royal Forest Testing"
		else
			printf 'There are no diagnostic recordings to delete.\n'
		fi
		return 0
	fi
	local preview=""
	for path in "${files[@]}"; do preview+="${path}"$'\n'; done
	if command -v kdialog >/dev/null 2>&1; then
		kdialog --warningyesno "Delete these ${#files[@]} diagnostic files?\n\n$preview" \
			--title "Royal Forest Testing — Confirm deletion" || return 0
	else
		printf 'Refusing non-interactive deletion. Exact targets:\n%s' "$preview" >&2
		return 1
	fi
	rm -rf -- "${files[@]}"
	kdialog --msgbox "Deleted ${#files[@]} diagnostic recording targets." --title "Royal Forest Testing"
}

package_latest_recording() {
	mkdir -p "$RECORDINGS_DIR" "$EXPORTS_DIR"
	local latest_file="$RECORDINGS_DIR/latest.txt"
	if [[ ! -s "$latest_file" ]]; then
		show_error "No latest diagnostic session was found. Record one with F9 first."
		exit 1
	fi
	local session_id
	session_id="$(tr -d '\r\n' < "$latest_file")"
	if [[ ! "$session_id" =~ ^rf-[0-9]{8}-[0-9]{6}$ ]]; then
		show_error "The latest session pointer is invalid: $session_id"
		exit 1
	fi
	local mp4="$RECORDINGS_DIR/$session_id.mp4"
	local telemetry="$RECORDINGS_DIR/$session_id.jsonl"
	if [[ ! -s "$mp4" || ! -s "$telemetry" ]]; then
		show_error "The newest recording is still processing or incomplete. Wait for VIDEO READY in game, then try again."
		exit 1
	fi
	local -a files=("$mp4" "$telemetry")
	[[ -f "$RECORDINGS_DIR/$session_id.video.log" ]] && files+=("$RECORDINGS_DIR/$session_id.video.log")
	local archive="$EXPORTS_DIR/royal-forest-diagnostic-$session_id.zip"
	python3 - "$archive" "${files[@]}" <<'PY'
import sys, zipfile
from pathlib import Path
archive = Path(sys.argv[1])
with zipfile.ZipFile(archive, "w", zipfile.ZIP_DEFLATED) as output:
    for raw in sys.argv[2:]:
        path = Path(raw)
        output.write(path, path.name)
print(archive)
PY
	if command -v kdialog >/dev/null 2>&1; then
		kdialog --msgbox "Packaged newest diagnostic session:\n$archive" --title "Royal Forest Testing"
	else
		printf '%s\n' "$archive"
	fi
}

case "${1:-}" in
	--play) play_game ;;
	--tests) run_tests ;;
	--tests-inline) run_tests_inline ;;
	--guide) open_guide ;;
	--open-recordings) open_recordings ;;
	--delete-recordings) delete_recordings ;;
	--package-latest-recording) package_latest_recording ;;
	--recordings-path) printf '%s\n' "$RECORDINGS_DIR" ;;
	"")
		if ! command -v kdialog >/dev/null 2>&1; then
			play_game
		fi
		choice="$(kdialog --title "Royal Forest Testing" --menu "Current checkout: $(current_build_label)\n\nWhat would you like to do?" \
			play "Play the current build" \
			tests "Run every automated verification check" \
			guide "Open the current playtest guide" \
			recordings "Open diagnostic recordings" \
			package "Package newest recording for sharing" \
			delete "Delete diagnostic recordings (preview + confirm)")" || exit 0
		case "$choice" in
			play) play_game ;;
			tests) run_tests ;;
			guide) open_guide ;;
			recordings) open_recordings ;;
			package) package_latest_recording ;;
			delete) delete_recordings ;;
		esac
		;;
	*)
		printf 'Usage: %s [--play|--tests|--tests-inline|--guide|--open-recordings|--delete-recordings|--package-latest-recording|--recordings-path]\n' "$0" >&2
		exit 2
		;;
esac
