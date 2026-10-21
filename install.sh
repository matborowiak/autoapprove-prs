#!/bin/bash
# Install autoapprove-prs as a macOS launchd agent that runs on an interval.
# Every argument after the options is passed through to autoapprove-prs.
set -e
PROG=$(basename "$0")
DIR=$(cd "$(dirname "$0")" && pwd)
INTERVAL=120

usage() {
  cat <<USAGE
Usage: $PROG [--interval <seconds>] [--name <name>] -- <autoapprove-prs args>

Creates ~/Library/LaunchAgents/io.github.autoapprove-prs.<name>.plist and loads it.
Running it again with the same name replaces that job.

  --interval <s>   seconds between runs (default 120)
  --name <name>    job name (default: owner-repo taken from --repo)

Example:
  $PROG --interval 300 -- --repo acme/widgets --author alice,bob
USAGE
}

NAME=""
while [ $# -gt 0 ]; do
  case "$1" in
    --interval) INTERVAL=$2; shift 2 ;;
    --name)     NAME=$2; shift 2 ;;
    -h|--help)  usage; exit 0 ;;
    --)         shift; break ;;
    *)          break ;;
  esac
done
[ $# -gt 0 ] || { usage >&2; exit 2; }
case "$INTERVAL" in ''|*[!0-9]*) echo "$PROG: --interval must be a number of seconds" >&2; exit 2 ;; esac

# Check the arguments with a dry run before scheduling anything.
"$DIR/autoapprove-prs" "$@" --dry-run --quiet --no-notify >/dev/null

if [ -z "$NAME" ]; then
  prev=""
  for a in "$@"; do
    case "$prev" in -r|--repo) NAME=$a ;; esac
    case "$a" in --repo=*) NAME=${a#*=} ;; esac
    prev=$a
  done
  NAME=$(printf '%s' "$NAME" | sed -E 's#^(https?://)?(www\.)?github\.com[/:]##; s#^git@github\.com:##; s#\.git$##' \
    | cut -d/ -f1-2 | tr '/' '-' | tr -c 'A-Za-z0-9._-' '-' | sed 's/-*$//')
fi
[ -n "$NAME" ] || { echo "$PROG: couldn't derive a job name; pass --name" >&2; exit 2; }

LABEL=io.github.autoapprove-prs.$NAME
PLIST=~/Library/LaunchAgents/$LABEL.plist
LOG=~/Library/Logs/autoapprove-prs.$NAME.log

xml() { printf '%s' "$1" | sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g'; }
args="    <string>/bin/bash</string>
    <string>$(xml "$DIR/autoapprove-prs")</string>"
for a in "$@"; do args="$args
    <string>$(xml "$a")</string>"; done

mkdir -p ~/Library/LaunchAgents ~/Library/Logs
cat > "$PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>$LABEL</string>
  <key>ProgramArguments</key>
  <array>
$args
  </array>
  <key>EnvironmentVariables</key>
  <dict><key>PATH</key><string>$(xml "$(dirname "$(command -v gh)"):/usr/bin:/bin")</string></dict>
  <key>StartInterval</key><integer>$INTERVAL</integer>
  <key>RunAtLoad</key><true/>
  <key>StandardOutPath</key><string>$(xml "$LOG")</string>
  <key>StandardErrorPath</key><string>$(xml "$LOG")</string>
</dict>
</plist>
PLIST
plutil -lint -s "$PLIST"

launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$PLIST"
echo "Loaded $LABEL (every ${INTERVAL}s)"
echo "Logs:      tail -f $LOG"
echo "Uninstall: $DIR/uninstall.sh $NAME"
