#!/usr/bin/env bash
# Remove the sample subagents that install.sh put in place.
#
#   bash ~/.subagent-starter-kit/uninstall.sh            preview, ask once, remove
#   bash ~/.subagent-starter-kit/uninstall.sh --dry-run  preview only
#
# Removes only files that still match the copy the kit installed. A file you
# edited since is left alone. A file of yours that install.sh --force
# replaced is restored from its backup. Works on bash 3.2 and bash 5.
set -eu

STATE_DIR="$HOME/.subagent-starter-kit"
STATE="$STATE_DIR/installed.tsv"
DRY=0 YES=0

usage() {
  cat <<'USAGE'
Usage: bash ~/.subagent-starter-kit/uninstall.sh [options]

  --dry-run   show what would change, change nothing
  --yes, -y   do not ask first
  -h, --help  show this help
USAGE
}

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY=1 ;;
    --yes|-y) YES=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $arg" >&2; usage >&2; exit 2 ;;
  esac
done

# Show paths as ~/... in messages (the tilde is meant literally here).
# shellcheck disable=SC2088
tilde() { case "$1" in "$HOME"/*) printf '~/%s' "${1#"$HOME"/}" ;; *) printf '%s' "$1" ;; esac; }
sum() { cksum < "$1" | awk '{ print $1 "-" $2 }'; }

if [ ! -s "$STATE" ]; then
  echo "Nothing to remove: the kit has no install record in $(tilde "$STATE_DIR")/."
  exit 0
fi

echo "Subagent starter kit: uninstall plan"
removals=0
while IFS="$(printf '\t')" read -r dest s backup; do
  [ -n "$dest" ] || continue
  if [ ! -e "$dest" ] && [ ! -L "$dest" ]; then
    echo "  gone     $(tilde "$dest") (already removed)"
  elif [ -f "$dest" ] && [ ! -L "$dest" ] && [ "$(sum "$dest")" = "$s" ]; then
    if [ "$backup" != "-" ] && [ -f "$backup" ]; then
      echo "  restore  $(tilde "$dest") (your file from before the install)"
    else
      echo "  remove   $(tilde "$dest")"
    fi
    removals=$((removals + 1))
  else
    echo "  keep     $(tilde "$dest") (changed since the install; left alone)"
  fi
done < "$STATE"

if [ "$DRY" = 1 ]; then echo "Dry run: nothing changed."; exit 0; fi
if [ "$YES" = 0 ]; then
  if [ ! -t 0 ]; then echo "No terminal to ask. Re-run with --yes to uninstall." >&2; exit 1; fi
  printf 'Uninstall? [y/N] '
  read -r answer || answer=""
  case "$answer" in y|Y|yes|YES) ;; *) echo "Nothing changed."; exit 1 ;; esac
fi

while IFS="$(printf '\t')" read -r dest s backup; do
  [ -n "$dest" ] || continue
  if [ -f "$dest" ] && [ ! -L "$dest" ] && [ "$(sum "$dest")" = "$s" ]; then
    rm -f "$dest"
    if [ "$backup" != "-" ] && [ -f "$backup" ]; then cp -P "$backup" "$dest"; fi
  fi
done < "$STATE"

rm -f "$STATE" "$STATE_DIR/uninstall.sh"
if [ -d "$STATE_DIR/backups" ]; then
  echo "Done. Backups are kept in $(tilde "$STATE_DIR")/backups/; delete that folder when you no longer need them."
else
  rmdir "$STATE_DIR" 2>/dev/null || true
  echo "Done."
fi
