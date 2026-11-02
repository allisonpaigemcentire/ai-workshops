#!/bin/bash
# Claude Code statusLine script
# Shows, in order: model | cwd | git repo/branch | open PR | context usage
input=$(cat)

RESET=$'\033[0m'
CYAN=$'\033[36m'
BLUE=$'\033[34m'
GREEN=$'\033[32m'
YELLOW=$'\033[33m'
MAGENTA=$'\033[35m'
DIM=$'\033[2m'

model=$(echo "$input" | jq -r '.model.display_name // empty')
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')
# Not ${cwd/#$HOME/~}: bash 5 expands that ~ back to $HOME.
case "$cwd" in
  "$HOME") dir_display="~" ;;
  "$HOME"/*) dir_display="~${cwd#"$HOME"}" ;;
  *) dir_display="$cwd" ;;
esac

repo=$(echo "$input" | jq -r '.workspace.repo | if . then .owner + "/" + .name else empty end')

# Git branch, derived via git (skips optional locks; not part of the JSON payload)
branch=""
if [ -n "$cwd" ] && git --no-optional-locks -C "$cwd" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch=$(git --no-optional-locks -C "$cwd" rev-parse --abbrev-ref HEAD 2>/dev/null)
fi

git_info=""
if [ -n "$repo" ] && [ -n "$branch" ]; then
  git_info="${repo}:${branch}"
elif [ -n "$repo" ]; then
  git_info="$repo"
elif [ -n "$branch" ]; then
  git_info="$branch"
fi

pr_number=$(echo "$input" | jq -r '.pr.number // empty')
pr_state=$(echo "$input" | jq -r '.pr.review_state // empty')
pr_info=""
if [ -n "$pr_number" ]; then
  if [ -n "$pr_state" ]; then
    pr_info="PR #${pr_number} (${pr_state})"
  else
    pr_info="PR #${pr_number}"
  fi
fi

used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
ctx_info=""
if [ -n "$used_pct" ]; then
  ctx_info=$(LC_ALL=C printf "Ctx %.0f%%" "$used_pct" 2>/dev/null) || ctx_info=""
fi

parts=()
[ -n "$model" ] && parts+=("${CYAN}${model}${RESET}")
[ -n "$dir_display" ] && parts+=("${BLUE}${dir_display}${RESET}")
[ -n "$git_info" ] && parts+=("${GREEN}${git_info}${RESET}")
[ -n "$pr_info" ] && parts+=("${YELLOW}${pr_info}${RESET}")
[ -n "$ctx_info" ] && parts+=("${MAGENTA}${ctx_info}${RESET}")

output=""
sep="${DIM} | ${RESET}"
for p in "${parts[@]}"; do
  if [ -z "$output" ]; then
    output="$p"
  else
    output="${output}${sep}${p}"
  fi
done

printf "%s\n" "$output"
