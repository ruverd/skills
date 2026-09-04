#!/usr/bin/env bash
# Fail closed if the walk start sample is a login wall. Stop may be a
# login wall (S10 last frame). Text snapshots only. No ffmpeg, no
# network, no WebM parse.
#
# Usage:
#   walk-video-gate.sh --start start.txt [--middle mid.txt] [--stop stop.txt]
#   walk-video-gate.sh --text-file start.txt [--text-file more.txt]
#
set -euo pipefail

print_usage() {
  sed -n '2,9p' "$0" | sed 's/^# \?//'
}

usage() {
  print_usage
  exit 1
}

need_file() {
  [[ $# -ge 2 ]] || usage
  [[ -f "$2" ]] || { echo "sample does not exist: $2" >&2; exit 1; }
}

is_login_wall() {
  grep -Eiq 'sign in|check your email|magic link|qa:login|/login' -- "$1"
}

start=""
text_files=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --start)
      need_file "$@"
      start="$2"
      shift 2
      ;;
    --middle|--stop)
      need_file "$@"
      shift 2
      ;;
    --text-file)
      need_file "$@"
      text_files+=("$2")
      shift 2
      ;;
    -h|--help)
      print_usage
      exit 0
      ;;
    *)
      echo "unknown arg: $1" >&2
      usage
      ;;
  esac
done

if [[ -z "$start" ]]; then
  [[ ${#text_files[@]} -gt 0 ]] || { echo "missing --start" >&2; exit 1; }
  start="${text_files[0]}"
fi

if is_login_wall "$start"; then
  echo "start sample is a login wall: $start" >&2
  exit 1
fi
exit 0
