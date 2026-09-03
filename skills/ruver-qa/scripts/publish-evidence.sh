#!/usr/bin/env bash
# Publish ruver-qa video + screenshots to a secret gist.
#
# gh gist create (2.58+) rejects binary. Create a text gist, then git-push
# media into it. GitHub comments will not inline-play gist video; link the
# gist + raw files.
#
# Usage:
#   publish-evidence.sh --repo owner/repo --pr N --sha OID
#     [--video path.webm] [--artifacts dir] [--out path]
#     [--screenshot path]   (repeat for each PNG)
#
# Prints key=value lines. Exit 0 on gist+push; 2 if upload failed
# (still printed local paths. Caller must still post the PR comment).

set -euo pipefail

REPO=""
PR=""
SHA=""
VIDEO=""
ARTIFACTS=""
OUT=""
SCREENSHOTS=()

usage() {
  sed -n '2,14p' "$0" | sed 's/^# \?//'
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo) REPO="${2:-}"; shift 2 ;;
    --pr) PR="${2:-}"; shift 2 ;;
    --sha) SHA="${2:-}"; shift 2 ;;
    --video) VIDEO="${2:-}"; shift 2 ;;
    --artifacts) ARTIFACTS="${2:-}"; shift 2 ;;
    --screenshot) SCREENSHOTS+=("${2:-}"); shift 2 ;;
    --out) OUT="${2:-}"; shift 2 ;;
    -h|--help) usage ;;
    *) echo "unknown arg: $1" >&2; usage ;;
  esac
done

[[ -n "$REPO" && -n "$PR" && -n "$SHA" ]] || usage

if [[ -z "$VIDEO" ]]; then
  VIDEO=$(find test-results .ruver-qa/artifacts -name '*.webm' 2>/dev/null | head -1 || true)
fi

if [[ -z "$ARTIFACTS" ]]; then
  if [[ -d .ruver-qa/artifacts ]]; then
    ARTIFACTS=.ruver-qa/artifacts
  fi
fi

LOGIN=$(gh api user --jq .login)
DESC="ruver-qa video ${REPO}#${PR} ${SHA}"
NOTES=$(mktemp)
printf '%s\n' "$DESC" >"$NOTES"

emit() {
  printf '%s\n' "$@"
  if [[ -n "$OUT" ]]; then
    printf '%s\n' "$@" >>"$OUT"
  fi
}

fail_upload() {
  emit "STATUS=failed"
  emit "GIST_URL="
  emit "ERROR=${1}"
  [[ -n "$VIDEO" ]] && emit "LOCAL_VIDEO=${VIDEO}"
  exit 2
}

GIST_URL=$(gh gist create --desc "$DESC" "$NOTES") || fail_upload "gist create failed"
GIST_ID=$(basename "$GIST_URL")
WORKDIR=$(mktemp -d)
trap 'rm -f "$NOTES"' EXIT

gh auth setup-git >/dev/null
git clone --quiet "https://gist.github.com/${GIST_ID}.git" "$WORKDIR" \
  || fail_upload "gist clone failed"

if [[ -n "$VIDEO" && -f "$VIDEO" ]]; then
  cp "$VIDEO" "$WORKDIR/qa.webm"
  if command -v ffmpeg >/dev/null; then
    ffmpeg -y -hide_banner -loglevel error \
      -i "$VIDEO" -c:v libx264 -pix_fmt yuv420p -movflags +faststart -an \
      "$WORKDIR/qa.mp4" || true
  fi
fi

if [[ -n "$ARTIFACTS" && -d "$ARTIFACTS" ]]; then
  find "$ARTIFACTS" -maxdepth 1 -name '*.png' -exec cp {} "$WORKDIR/" \;
fi

if [[ ${#SCREENSHOTS[@]} -gt 0 ]]; then
  for shot in "${SCREENSHOTS[@]}"; do
    if [[ -n "$shot" && -f "$shot" ]]; then
      cp "$shot" "$WORKDIR/$(basename "$shot")"
    fi
  done
fi

git -C "$WORKDIR" add -A
if git -C "$WORKDIR" diff --cached --quiet; then
  emit "STATUS=ok"
  emit "GIST_URL=${GIST_URL}"
  emit "NOTE=no media files found to push"
  exit 0
fi

git -C "$WORKDIR" \
  -c "user.email=${LOGIN}@users.noreply.github.com" \
  -c "user.name=${LOGIN}" \
  commit --quiet -m "qa media ${REPO}#${PR} ${SHA}"
git -C "$WORKDIR" push --quiet origin HEAD || fail_upload "gist push failed"

RAW="https://gist.githubusercontent.com/${LOGIN}/${GIST_ID}/raw"
emit "STATUS=ok"
emit "GIST_URL=${GIST_URL}"
[[ -f "$WORKDIR/qa.mp4" ]] && emit "VIDEO_MP4=${RAW}/qa.mp4"
[[ -f "$WORKDIR/qa.webm" ]] && emit "VIDEO_WEBM=${RAW}/qa.webm"
if compgen -G "$WORKDIR/*.png" >/dev/null; then
  for png in "$WORKDIR"/*.png; do
    emit "SCREENSHOT=${RAW}/$(basename "$png")"
  done
fi
exit 0
