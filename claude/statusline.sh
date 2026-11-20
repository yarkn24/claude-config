#!/bin/bash
input=$(cat)

if ! command -v jq >/dev/null 2>&1; then
  printf "%s\n" "$(basename "$PWD")"
  exit 0
fi

model=$(echo "$input" | jq -r '.model.display_name // "?"')
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // "?"')
pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

dir_name=$(basename "$cwd" 2>/dev/null)
branch=""
if git -C "$cwd" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch=$(git -C "$cwd" branch --show-current 2>/dev/null)
  [ -n "$branch" ] && branch=" ($branch)"
fi

GREEN=$'\033[32m'
YELLOW=$'\033[33m'
RED=$'\033[31m'
RESET=$'\033[0m'

ctx=""
if [ -n "$pct" ]; then
  pct_int=${pct%.*}
  color="$GREEN"
  if [ "$pct_int" -ge 80 ]; then
    color="$RED"
  elif [ "$pct_int" -ge 50 ]; then
    color="$YELLOW"
  fi
  ctx=" | ${color}ctx:${pct_int}%${RESET}"
fi

printf "%s | %s%s%s\n" "$model" "$dir_name" "$branch" "$ctx"
