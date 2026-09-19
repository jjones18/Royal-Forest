#!/usr/bin/env bash
# Convert Royal Forest's in-game frame sequence to a compact diagnostic MP4.
# Usage: record_clip.sh encode SESSION_ID RECORDINGS_DIR
set -euo pipefail

mode="${1:-}"
session_id="${2:-}"
recordings_dir="${3:-}"

if [[ "$mode" != "encode" || -z "$session_id" || -z "$recordings_dir" ]]; then
	printf 'Usage: %s encode SESSION_ID RECORDINGS_DIR\n' "$0" >&2
	exit 2
fi
if [[ ! "$session_id" =~ ^rf-[0-9]{8}-[0-9]{6}$ ]]; then
	printf 'Invalid session id: %s\n' "$session_id" >&2
	exit 2
fi

frames_dir="$recordings_dir/.frames-$session_id"
final="$recordings_dir/$session_id.mp4"
log="$recordings_dir/$session_id.video.log"
mkdir -p "$recordings_dir"

if ! command -v ffmpeg >/dev/null 2>&1 || ! command -v ffprobe >/dev/null 2>&1; then
	printf 'ffmpeg/ffprobe unavailable; keeping temporary frames.\n' >"$log"
	exit 3
fi
if [[ ! -s "$frames_dir/frame-000000.jpg" ]]; then
	printf 'No captured frames found in %s.\n' "$frames_dir" >"$log"
	exit 1
fi

rm -f -- "$final"
if ffmpeg -hide_banner -loglevel error -y \
	-framerate 24 -start_number 0 -i "$frames_dir/frame-%06d.jpg" \
	-vf "scale=1280:720:force_original_aspect_ratio=decrease:force_divisible_by=2" \
	-c:v libx264 -preset veryfast -crf 30 -pix_fmt yuv420p \
	-movflags +faststart -an "$final" >>"$log" 2>&1 \
	&& [[ -s "$final" ]] \
	&& [[ "$(ffprobe -v error -select_streams v:0 -show_entries stream=r_frame_rate -of default=noprint_wrappers=1:nokey=1 "$final")" == "24/1" ]]; then
	rm -rf -- "$frames_dir"
	printf '%s\n' "$session_id" >"$recordings_dir/latest.txt"
	printf 'Created verified 24 FPS video: %s\n' "$final" >>"$log"
else
	rm -f -- "$final"
	printf '24 FPS conversion failed; keeping temporary frames in %s.\n' "$frames_dir" >>"$log"
	exit 1
fi
