#!/bin/bash
# PreToolUse hook, matcher ExitPlanMode. Rejects a plan that lacks the required structure.
# ExitPlanMode carries no plan content; the plan is the newest ~/.claude/plans/*.md file.
cat >/dev/null
PLANS_DIR="$HOME/.claude/plans"
plan_file=$(ls -t "$PLANS_DIR"/*.md 2>/dev/null | head -1)
if [ -z "$plan_file" ]; then
  echo "FAIL: no plan file found in $PLANS_DIR. Write the plan to the plan file before exiting plan mode." >&2
  exit 2
fi
python3 "$(dirname "$0")/plan_detail_gate_checks.py" "$plan_file"
exit $?
