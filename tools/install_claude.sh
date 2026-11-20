#!/usr/bin/env bash
# Installs claude/ into ~/.claude (idempotent, backs up what it changes), installs the recommended plugins, then runs the self-check.
# Usage: bash tools/install_claude.sh [--check-only] [--no-plugins] [--home DIR]
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$REPO/claude"
TARGET_HOME="$HOME"; CHECK_ONLY=0; NO_PLUGINS=0
while [ $# -gt 0 ]; do
  case "$1" in
    --check-only) CHECK_ONLY=1 ;;
    --no-plugins) NO_PLUGINS=1 ;;
    --home) TARGET_HOME="$2"; shift ;;
    *) echo "unknown option: $1"; exit 2 ;;
  esac; shift
done
CL="$TARGET_HOME/.claude"
export RECOMMENDED_PLUGINS="superpowers@claude-plugins-official feature-dev@claude-plugins-official code-review@claude-plugins-official code-simplifier@claude-plugins-official commit-commands@claude-plugins-official claude-md-management@claude-plugins-official claude-code-setup@claude-plugins-official security-guidance@claude-plugins-official session-report@claude-plugins-official ralph-loop@claude-plugins-official document-skills@anthropic-agent-skills example-skills@anthropic-agent-skills claude-api@anthropic-agent-skills"
PY="$(command -v python3 || true)"
if [ -z "$PY" ] || ! "$PY" -c 'import json' >/dev/null 2>&1; then
  echo "FAIL python3 not found or not runnable (hooks and this installer need it). Install Python 3, reopen the terminal, rerun."; exit 1
fi

if [ "$CHECK_ONLY" = 0 ]; then
  STAMP="$(date +%Y%m%d-%H%M%S)"; BK="$CL/backups/claude-config-$STAMP"; mkdir -p "$CL"
  "$PY" - "$SRC" "$CL" "$BK" <<'PYEOF'
import json, os, shutil, sys, filecmp
src, cl, bk = sys.argv[1:4]
backed = changed = 0
def backup(rel):
    global backed
    dst = os.path.join(cl, rel)
    if os.path.exists(dst):
        b = os.path.join(bk, rel); os.makedirs(os.path.dirname(b), exist_ok=True); shutil.copy2(dst, b); backed += 1
for root, dirs, files in os.walk(src):
    dirs[:] = [d for d in dirs if d != "__pycache__"]
    for f in files:
        if f.endswith(".pyc") or f == ".DS_Store": continue
        rel = os.path.relpath(os.path.join(root, f), src)
        if rel == "settings.json" or rel.startswith("paste" + os.sep): continue
        dst = os.path.join(cl, rel)
        if os.path.exists(dst) and filecmp.cmp(os.path.join(root, f), dst, shallow=False): continue
        backup(rel); os.makedirs(os.path.dirname(dst), exist_ok=True); shutil.copy2(os.path.join(root, f), dst); changed += 1
# settings.json: package keys win, existing extra keys stay, permission lists and hooks are unioned.
pkg = json.load(open(os.path.join(src, "settings.json")))
sp = os.path.join(cl, "settings.json")
cur = json.load(open(sp)) if os.path.exists(sp) else {}
new = dict(cur)
for k, v in pkg.items():
    if k == "permissions":
        perms = dict(cur.get("permissions", {}))
        for lk, lv in v.items():
            perms[lk] = list(dict.fromkeys(perms.get(lk, []) + lv)) if isinstance(lv, list) else lv
        new[k] = perms
    elif k == "env":
        new[k] = {**cur.get("env", {}), **v}
    elif k == "hooks":
        hooks = json.loads(json.dumps(v))
        for ev, blocks in cur.get("hooks", {}).items():
            have = {h.get("command") for b in hooks.get(ev, []) for h in b.get("hooks", [])}
            for b in blocks:
                extra = [h for h in b.get("hooks", []) if h.get("command") not in have]
                if extra: hooks.setdefault(ev, []).append({**b, "hooks": extra})
        new[k] = hooks
    else:
        new[k] = v
if new != cur:
    backup("settings.json"); json.dump(new, open(sp, "w"), indent=2); changed += 1
print(f"INSTALL files changed: {changed}, backed up: {backed}" + (f" -> {bk}" if backed else ""))
PYEOF
  chmod +x "$CL"/hooks/*.sh "$CL"/statusline.sh 2>/dev/null
  mkdir -p "$CL/memory" "$CL/logs"
  echo; echo "== PLUGINS"
  if [ "$NO_PLUGINS" = 1 ]; then echo "skipped (--no-plugins)"
  elif ! command -v claude >/dev/null 2>&1; then echo "skipped: claude CLI not on PATH. Install Claude Code, then rerun this script."
  else
    cc() { env -u CLAUDE_CONFIG_DIR HOME="$TARGET_HOME" claude "$@"; }
    have=" $("$PY" -c 'import json,sys; print(" ".join(json.load(open(sys.argv[1])).get("plugins", {})))' "$CL/plugins/installed_plugins.json" 2>/dev/null) "
    for m in anthropics/claude-plugins-official anthropics/skills; do
      out="$(cc plugin marketplace add "$m" 2>&1)" || echo "marketplace $m: $(echo "$out" | tail -1)"
    done
    for p in $RECOMMENDED_PLUGINS; do
      case "$have" in *" $p "*) echo "already installed $p"; continue ;; esac
      if out="$(cc plugin install "$p" 2>&1)"; then echo "installed $p"; else echo "NOT INSTALLED $p: $(echo "$out" | tail -1) (rerun: claude plugin install $p)"; fi
    done
  fi
fi

echo
echo "== SELF-CHECK ($CL)"
"$PY" - "$CL" "$SRC" <<'PYEOF'
import json, os, re, subprocess, sys, shutil, warnings
warnings.simplefilter("ignore", SyntaxWarning)
cl, src = sys.argv[1:3]
home = os.path.dirname(cl)
res = []
def item(ok, name, detail=""): res.append(ok); print(f"{'PASS' if ok else 'FAIL'} {name}" + (f": {detail}" if detail else ""))
def info(name, detail): print(f"INFO {name}: {detail}")
cm = os.path.join(cl, "CLAUDE.md")
size = os.path.getsize(cm) if os.path.exists(cm) else 0
item(size > 5000, "CLAUDE.md present and non-trivial", f"{size} bytes")
def imports(path):
    out = []
    for line in open(path, encoding="utf-8"):
        m = re.match(r"@(\S+)\s*$", line.strip())
        if m: out.append(m.group(1))
    return out
if size:
    for imp in imports(cm):
        p = os.path.join(cl, os.path.expanduser(imp)) if not imp.startswith("~") else os.path.expanduser(imp).replace(os.path.expanduser("~"), home, 1)
        ok = os.path.isfile(p) and os.path.getsize(p) > 0
        item(ok, f"@import {imp} resolves", p)
    text = open(cm, encoding="utf-8").read()
    for f in os.listdir(cl):
        if f.endswith(".md") and f != "CLAUDE.md" and os.path.isfile(os.path.join(cl, f)):
            text += open(os.path.join(cl, f), encoding="utf-8").read()
    refs = sorted(set(re.findall(r"~/\.claude/([A-Za-z0-9_./-]+\.(?:md|sh|py))", text)))
    missing = [r for r in refs if not os.path.exists(os.path.join(cl, r))]
    item(not missing, f"~/.claude paths named in CLAUDE.md and its imports exist ({len(refs)} checked)", ", ".join(missing))
sp = os.path.join(cl, "settings.json")
try:
    s = json.load(open(sp)); item(True, "settings.json is valid JSON")
except Exception as e:
    s = {}; item(False, "settings.json is valid JSON", str(e))
info("model", f"{s.get('model', '<unset: account default>')}, effortLevel {s.get('effortLevel', '<unset>')}, permission mode {s.get('permissions', {}).get('defaultMode', '<unset>')}")
cmds = [h.get("command", "") for blocks in s.get("hooks", {}).values() for b in blocks for h in b.get("hooks", [])]
bad = []
for c in cmds:
    m = re.search(r"(~|\$HOME)?(/\.claude/[^\s\"']+)", c)
    if not m: bad.append(f"{c} (no ~/.claude path)"); continue
    p = home + m.group(2)
    if not os.path.isfile(p): bad.append(f"{p} missing")
    elif not os.access(p, os.X_OK): bad.append(f"{p} not executable")
item(cmds and not bad, f"every hook in settings.json exists and is executable ({len(cmds)} hooks)", "; ".join(bad))
sh = shutil.which("bash")
item(bool(sh), "bash on PATH (hooks run as `bash ~/.claude/hooks/x.sh`)", sh or "")
synerr = []
for f in sorted(os.listdir(os.path.join(cl, "hooks"))) if os.path.isdir(os.path.join(cl, "hooks")) else []:
    p = os.path.join(cl, "hooks", f)
    if f.endswith(".sh") and sh and subprocess.run([sh, "-n", p], capture_output=True).returncode: synerr.append(f)
    if f.endswith(".py"):
        try: compile(open(p, encoding="utf-8").read(), p, "exec")
        except SyntaxError: synerr.append(f)
item(not synerr, "hook scripts pass a syntax check", ", ".join(synerr))
def count(kind):
    d = os.path.join(cl, kind)
    if kind == "skills": return {x for x in os.listdir(d) if os.path.isfile(os.path.join(d, x, "SKILL.md"))} if os.path.isdir(d) else set()
    return {x for x in os.listdir(d) if x.endswith(".md")} if os.path.isdir(d) else set()
for kind in ("skills", "commands", "agents", "reference"):
    have, want = count(kind), {x for x in (os.listdir(os.path.join(src, kind)) if os.path.isdir(os.path.join(src, kind)) else [])
                               if kind != "skills" or os.path.isfile(os.path.join(src, kind, x, "SKILL.md"))}
    miss = sorted(want - have)
    item(not miss, f"{kind}: {len(have)} installed, all {len(want)} from the package present", ", ".join(miss))
item(os.path.isfile(os.path.join(cl, "commands", "afk.md")), "/afk command present")
claude = shutil.which("claude")
if claude:
    v = subprocess.run([claude, "--version"], capture_output=True, text=True).stdout.strip()
    info("claude", f"{claude} {v}")
else:
    info("claude", "CLI not on PATH (VS Code extension only is fine)")
info("rtk", shutil.which("rtk") or "not installed (RTK.md rules are inert without it)")
ip = os.path.join(cl, "plugins", "installed_plugins.json")
try: have = set(json.load(open(ip)).get("plugins", {}))
except Exception: have = set()
recs = os.environ["RECOMMENDED_PLUGINS"].split()
info("plugins", f"{len([r for r in recs if r in have])}/{len(recs)} recommended installed; missing: " + ", ".join(r for r in recs if r not in have))
print(f"SELF-CHECK: {res.count(True)} PASS, {res.count(False)} FAIL")
sys.exit(0 if all(res) else 1)
PYEOF
RC=$?
cat <<'EOF'

== NEXT
The 13 recommended plugins are installed by this script (skip with --no-plugins).
Optional language servers: claude plugin install pyright-lsp@claude-plugins-official (or typescript-lsp).
Optional, they connect outside services (MCP), install only when the operator asks: exa, github, playwright, chrome-devtools-mcp, firecrawl (@claude-plugins-official).
Restart Claude Code after installing, then rerun: bash tools/install_claude.sh --check-only
EOF
exit $RC
