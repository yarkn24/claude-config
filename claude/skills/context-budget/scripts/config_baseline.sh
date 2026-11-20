#!/bin/bash
# config_baseline.sh: reusable measurement pass for the context-budget skill.
# Run from a project root to include that project's own CLAUDE.md/.claude/ in the count.
# Prints real numbers where a real source exists (claude CLI, wc, grep); estimates
# are left to the skill's own words*1.3 method for anything a real source can't answer.

echo "=== CLAUDE.md chain ==="
[ -f "$HOME/.claude/CLAUDE.md" ] && wc -l "$HOME/.claude/CLAUDE.md" | awk '{print "global: "$1" lines"}'
[ -f "./CLAUDE.md" ] && wc -l "./CLAUDE.md" | awk '{print "project (cwd): "$1" lines"}'

echo ""
echo "=== statusLine configured? ==="
python3 -c "
import json
d = json.load(open('$HOME/.claude/settings.json'))
print('YES' if 'statusLine' in d else 'NO')
"

echo ""
echo "=== .claude/rules/ present? ==="
ls -d "$HOME/.claude/rules" 2>/dev/null && echo "user: yes" || echo "user: no"
ls -d "./.claude/rules" 2>/dev/null && echo "project: yes" || echo "project: no"

echo ""
echo "=== registered hook command count ==="
for f in "$HOME/.claude/settings.json" "./.claude/settings.json" "./.claude/settings.local.json"; do
  [ -f "$f" ] || continue
  n=$(python3 -c "
import json
d = json.load(open('$f'))
h = d.get('hooks', {})
print(sum(len(entry.get('hooks', [])) for events in h.values() for entry in events))
" 2>/dev/null)
  echo "$f: $n"
done

echo ""
echo "=== agent/command defs marked DEPRECATED (still loaded) ==="
grep -rl "^description:.*DEPRECATED" "$HOME/.claude/agents" "$HOME/.claude/commands" ./.claude/agents ./.claude/commands 2>/dev/null

echo ""
echo "=== .bak clutter inside loaded agents/commands dirs ==="
find "$HOME/.claude/agents" "$HOME/.claude/commands" ./.claude/agents ./.claude/commands -iname "*.bak*" 2>/dev/null | wc -l | awk '{print $1" files (should be 0; move outside .claude/, moving to a subfolder INSIDE .claude/ only renames the namespace, does not hide it)"}'

echo ""
echo "=== enabled plugins: real always-on token cost (claude plugin details) ==="
claude plugin list --json 2>/dev/null | python3 -c "
import json, sys, subprocess
plugins = json.load(sys.stdin)
for p in plugins:
    if not p.get('enabled'):
        continue
    pid = p['id']
    try:
        out = subprocess.run(['claude', 'plugin', 'details', pid], capture_output=True, text=True, timeout=15).stdout
        for line in out.splitlines():
            if 'Always-on' in line:
                print(f'{pid}: {line.strip()}')
                break
    except Exception as e:
        print(f'{pid}: ERROR {e}')
"

echo ""
echo "=== duplicate skill/command names across enabled plugins + user + project ==="
python3 -c "
import json, subprocess, os
from collections import defaultdict

names = defaultdict(list)

def add_dir(d, source):
    if not os.path.isdir(d):
        return
    for entry in sorted(os.listdir(d)):
        p = os.path.join(d, entry)
        if os.path.isdir(p) and os.path.exists(os.path.join(p, 'SKILL.md')):
            names[entry].append(source)
        elif entry.endswith('.md') and os.path.isfile(p):
            names[entry[:-3]].append(source)

add_dir(os.path.expanduser('~/.claude/skills'), 'user:skills')
add_dir(os.path.expanduser('~/.claude/commands'), 'user:commands')
add_dir('./.claude/skills', 'project:skills')
add_dir('./.claude/commands', 'project:commands')

try:
    plugins = json.loads(subprocess.run(['claude','plugin','list','--json'], capture_output=True, text=True, timeout=15).stdout)
    for p in plugins:
        if not p.get('enabled'):
            continue
        ip = p.get('installPath')
        if not ip:
            continue
        add_dir(os.path.join(ip, 'skills'), p['id'])
        add_dir(os.path.join(ip, 'commands'), p['id'])
except Exception as e:
    print(f'plugin enumeration failed: {e}')

dupes = {k: v for k, v in names.items() if len(v) > 1}
if not dupes:
    print('none found')
for k, v in sorted(dupes.items()):
    print(f'{k}: {len(v)} copies -> {v}')
"

# Config-writing rules verified against official docs: ~/.claude/reference/claude_code_config_lessons.md
