#!/bin/bash
# Stop and remove launchd jobs created by install.sh. With no argument, lists them.
PREFIX=io.github.autoapprove-prs
if [ $# -eq 0 ]; then
  echo "Installed jobs (pass a name to remove one, or --all):"
  ls ~/Library/LaunchAgents 2>/dev/null | sed -n "s/^$PREFIX\.\(.*\)\.plist$/  \1/p"
  exit 0
fi
if [ "$1" = "--all" ]; then
  set -- $(ls ~/Library/LaunchAgents 2>/dev/null | sed -n "s/^$PREFIX\.\(.*\)\.plist$/\1/p")
fi
for name in "$@"; do
  label=$PREFIX.$name
  launchctl bootout "gui/$(id -u)/$label" 2>/dev/null && echo "Stopped $label" || echo "$label was not loaded"
  rm -f ~/Library/LaunchAgents/$label.plist
done
