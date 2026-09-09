#!/usr/bin/env bash
# Create one git worktree + branch per ticket, off the repo's default branch.
# Worktrees land in a sibling dir: ~/Documents/GitHub/.worktrees/<repo>/<TICKET>/
set -euo pipefail

WORKTREES_ROOT="${WORKTREES_ROOT:-$HOME/Documents/GitHub/.worktrees}"
REPO_PATH=""
BASE_OVERRIDE=""
DRY_RUN=0
YES=0
SPECS=()

CREATED=()   # "TICKET|branch|path"
EXISTED=()   # "TICKET|branch|path|reason"
FAILED=()    # "TICKET|reason"

usage() {
  cat <<'EOF'
Usage: create_worktree.sh [OPTIONS] TICKET[:slug] [TICKET[:slug] ...]

For each ticket, create a git worktree on a new branch `wt/<TICKET>[-<slug>]`
based on the repo's default branch. Worktrees are placed under
~/Documents/GitHub/.worktrees/<repo>/<TICKET>/.

Arguments:
  TICKET[:slug]         Ticket key, optionally with a branch slug.
                        e.g. TYP-1234  or  TYP-1234:fix-tray

Options:
  --repo PATH           Repo to operate on (default: repo containing CWD)
  --base BRANCH         Override the detected default/base branch
  --dry-run             Print intended branches/paths without creating anything
  --yes                 Reserved for non-interactive use (no prompts are issued)
  -h, --help            Show this help

Environment:
  WORKTREES_ROOT        Worktrees parent dir (default: ~/Documents/GitHub/.worktrees)

Exit status:
  0  at least one worktree created or already present
  1  usage error, or every ticket failed
EOF
}

die() { echo "error: $*" >&2; exit 1; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo) REPO_PATH="${2:-}"; shift 2 ;;
    --base) BASE_OVERRIDE="${2:-}"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    --yes) YES=1; shift ;;
    -h|--help) usage; exit 0 ;;
    --*) die "unknown option: $1" ;;
    *) SPECS+=("$1"); shift ;;
  esac
done

[[ ${#SPECS[@]} -gt 0 ]] || { usage; exit 1; }

# --- Resolve repo root ---------------------------------------------------------
if [[ -n "$REPO_PATH" ]]; then
  REPO_ROOT="$(git -C "$REPO_PATH" rev-parse --show-toplevel 2>/dev/null)" \
    || die "not a git repo: $REPO_PATH"
else
  REPO_ROOT="$(git -C "$PWD" rev-parse --show-toplevel 2>/dev/null)" \
    || die "not inside a git repo; pass --repo PATH"
fi
REPO_NAME="$(basename "$REPO_ROOT")"

# --- Fetch once ----------------------------------------------------------------
if [[ $DRY_RUN -eq 0 ]]; then
  git -C "$REPO_ROOT" fetch origin --prune --quiet || die "git fetch failed for $REPO_NAME"
fi

# --- Detect default (base) branch ----------------------------------------------
detect_default_branch() {
  local ref
  ref="$(git -C "$REPO_ROOT" symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null || true)"
  if [[ -n "$ref" ]]; then echo "${ref#origin/}"; return 0; fi

  if command -v gh >/dev/null 2>&1; then
    ref="$(gh repo view --json defaultBranchRef -q .defaultBranchRef.name 2>/dev/null || true)"
    if [[ -n "$ref" ]]; then echo "$ref"; return 0; fi
  fi

  local b
  for b in dev main master develop; do
    if git -C "$REPO_ROOT" show-ref --verify --quiet "refs/remotes/origin/$b"; then
      echo "$b"; return 0
    fi
  done
  return 1
}

if [[ -n "$BASE_OVERRIDE" ]]; then
  BASE="$BASE_OVERRIDE"
else
  BASE="$(detect_default_branch)" \
    || die "could not detect default branch for $REPO_NAME; pass --base BRANCH"
fi

if [[ $DRY_RUN -eq 0 ]] && ! git -C "$REPO_ROOT" show-ref --verify --quiet "refs/remotes/origin/$BASE"; then
  die "base branch origin/$BASE not found for $REPO_NAME"
fi

# --- Helpers -------------------------------------------------------------------
sanitize_slug() {
  # lowercase, non-alnum -> '-', collapse/trim dashes
  printf '%s' "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[^a-z0-9]+/-/g; s/-+/-/g; s/^-//; s/-$//'
}

worktree_exists_at() {
  git -C "$REPO_ROOT" worktree list --porcelain 2>/dev/null \
    | grep -qxF "worktree $1"
}

echo "Repo:  $REPO_NAME ($REPO_ROOT)"
echo "Base:  origin/$BASE"
[[ $DRY_RUN -eq 1 ]] && echo "Mode:  DRY RUN (no changes)"
echo

# --- Process each ticket -------------------------------------------------------
for spec in "${SPECS[@]}"; do
  ticket_raw="${spec%%:*}"
  slug_raw=""
  [[ "$spec" == *:* ]] && slug_raw="${spec#*:}"

  TICKET="$(printf '%s' "$ticket_raw" | tr '[:lower:]' '[:upper:]')"
  [[ -n "$TICKET" ]] || { FAILED+=("$spec|empty ticket"); continue; }

  branch="wt/$TICKET"
  if [[ -n "$slug_raw" ]]; then
    slug="$(sanitize_slug "$slug_raw")"
    [[ -n "$slug" ]] && branch="wt/$TICKET-$slug"
  fi

  wt_path="$WORKTREES_ROOT/$REPO_NAME/$TICKET"

  # Idempotency checks
  if worktree_exists_at "$wt_path"; then
    EXISTED+=("$TICKET|$branch|$wt_path|worktree already registered"); continue
  fi
  if git -C "$REPO_ROOT" show-ref --verify --quiet "refs/heads/$branch"; then
    EXISTED+=("$TICKET|$branch|$wt_path|branch already exists"); continue
  fi
  if [[ -e "$wt_path" ]]; then
    FAILED+=("$TICKET|path exists but is not a registered worktree: $wt_path"); continue
  fi

  if [[ $DRY_RUN -eq 1 ]]; then
    CREATED+=("$TICKET|$branch|$wt_path"); continue
  fi

  mkdir -p "$(dirname "$wt_path")"
  if git -C "$REPO_ROOT" worktree add --no-track -b "$branch" "$wt_path" "origin/$BASE" >/dev/null 2>&1; then
    CREATED+=("$TICKET|$branch|$wt_path")
  else
    FAILED+=("$TICKET|git worktree add failed (branch $branch)")
  fi
done

# --- Summary table -------------------------------------------------------------
print_row() { printf '  %-12s %-40s %-9s %s\n' "$1" "$2" "$3" "$4"; }

echo "Summary"
print_row "TICKET" "BRANCH" "STATUS" "PATH"
print_row "------" "------" "------" "----"
for e in "${CREATED[@]:-}"; do
  [[ -z "$e" ]] && continue
  IFS='|' read -r t b p <<<"$e"
  print_row "$t" "$b" "$([[ $DRY_RUN -eq 1 ]] && echo WOULD || echo CREATED)" "$p"
done
for e in "${EXISTED[@]:-}"; do
  [[ -z "$e" ]] && continue
  IFS='|' read -r t b p r <<<"$e"
  print_row "$t" "$b" "EXISTS" "$p"
done
for e in "${FAILED[@]:-}"; do
  [[ -z "$e" ]] && continue
  IFS='|' read -r t r <<<"$e"
  print_row "$t" "-" "ERROR" "$r"
done
echo

# --- Next steps for freshly created worktrees ----------------------------------
if [[ ${#CREATED[@]} -gt 0 && $DRY_RUN -eq 0 ]]; then
  echo "Next steps — open each path in its own editor window (do not git checkout in the primary tree):"
  for e in "${CREATED[@]}"; do
    IFS='|' read -r t b p <<<"$e"
    echo "  $t  ->  $p"
  done
  echo
  echo "Cleanup when done:  git -C \"$REPO_ROOT\" worktree remove <path> && git -C \"$REPO_ROOT\" worktree prune"
fi

# --- Exit status ---------------------------------------------------------------
if [[ ${#CREATED[@]} -eq 0 && ${#EXISTED[@]} -eq 0 ]]; then
  exit 1
fi
exit 0
