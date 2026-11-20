#!/bin/bash
# Delete Guard (PreToolUse, Bash): asks before any file delete, direct or indirect.
# Direct: rm, rmdir, unlink, shred, git rm, git clean (not -n), rsync --del*, find -delete/-exec, also behind
#   && || ; | & newline, $( ) `` <( ), heredocs, bash -c, eval, sudo/env/xargs wrappers, /bin/rm, \rm.
# Indirect: python -c / python scripts using shutil.rmtree, os.remove, unlink and similar.
# Roots (~/.claude, $CLAUDE_PROJECT_DIR, system temp) only change the wording; recursive, glob, home, .git and
#   unparseable commands get an ATTENTION note. Never hard-blocks, never silently allows a delete.
set -u
INPUT=$(cat)
IFS= read -r -d '' PY <<'PYEOF' || true
import json, os, re, shlex, sys, tempfile

d = json.loads(os.environ["INPUT"])
if str(d.get("tool_name", "")) not in ("", "Bash"):
    sys.exit(0)
CMD = str(d.get("tool_input", {}).get("command", "")).rstrip("\n")
ROOTS = [os.path.expanduser("~/.claude") + "/", "/tmp/", "/private/tmp/", os.path.realpath(tempfile.gettempdir()) + "/",
         tempfile.gettempdir().rstrip("/") + "/"]
if os.environ.get("CLAUDE_PROJECT_DIR"):
    ROOTS.append(os.environ["CLAUDE_PROJECT_DIR"].rstrip("/") + "/")
ROOTS = tuple(ROOTS)
KW = re.compile(r"(?<![\w.-])(rm|rmdir|unlink|zf_rm|shred|-delete|--del[\w-]*)(?![\w.-])", re.I)
PYDEL = re.compile(r"shutil\s*\.\s*rmtree|\brmtree\s*\(|\bos\s*\.\s*(remove|unlink|rmdir|removedirs)\s*\(|\.unlink\s*\(")
PYCMD = re.compile(r"python[\d.]*|pypy[\d.]*")
ASSIGN = re.compile(r"[A-Za-z_][A-Za-z0-9_]*(\[[^]]*\])?\+?=")
VAR = re.compile(r"\$(?:\{([A-Za-z_][A-Za-z0-9_]*)\}|([A-Za-z_][A-Za-z0-9_]*))")
SKIP = {"!", "{", "}", "if", "then", "else", "elif", "fi", "do", "done", "while", "until", "esac", "coproc"}
SHELLS = {"bash", "sh", "zsh", "dash", "ksh", "mksh", "fish"}
# wrapper -> short options that take a value
WRAP = {"sudo": "ugpChDrtUTR", "doas": "uC", "env": "uSPC", "nice": "n", "nohup": "", "time": "", "command": "",
        "builtin": "", "exec": "a", "noglob": "", "nocorrect": "", "-": "", "timeout": "sk", "gtimeout": "sk",
        "stdbuf": "ioe", "caffeinate": "tw", "arch": "", "xargs": "EIJLPRSadns", "watch": "n"}
GIT_ARG_OPTS = {"-C", "-c", "--git-dir", "--work-tree", "--namespace", "--config-env", "--super-prefix"}


def ask(msg):
    print(json.dumps({"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "ask",
                                             "permissionDecisionReason": msg}}))
    sys.exit(0)


class Doubt(Exception):
    pass


class Lexer:
    """Splits shell text into simple commands {w: [(word, dynamic)], stdin, piped}; substitutions and heredocs too."""

    def __init__(self, s, cmds):
        self.s, self.cmds = s, cmds

    def new(self, piped):
        self.cmds.append({"w": [], "stdin": [], "piped": piped})
        return self.cmds[-1]

    def expand(self, i, buf):  # s[i] is $ or `
        s = self.s
        if s[i] == "`":
            j, out = i + 1, []
            while j < len(s) and s[j] != "`":
                esc = s[j] == "\\" and j + 1 < len(s)
                out.append((s[j + 1] if s[j + 1] in "`$\\" else s[j:j + 2]) if esc else s[j])
                j += 1 + esc
            if j >= len(s):
                raise Doubt("unclosed backtick")
            Lexer("".join(out), self.cmds).lex(0, None)
            j += 1
        elif s.startswith("$((", i):
            j = self.balanced(i + 3, 2, "()")
        elif s.startswith("$(", i):
            j = self.lex(i + 2, ")")
        elif s.startswith("${", i):
            j = self.balanced(i + 2, 1, "{}")
        else:
            j = i + 1
        buf.append(s[i:j])
        return j

    def balanced(self, i, depth, pair):  # $(( )) or ${ }: nested $( ) and `` are still lexed
        s = self.s
        while i < len(s):
            c = s[i]
            if pair == "{}" and c == "\\":
                i += 2
            elif c == "`" or (c == "$" and (pair == "{}" or s.startswith("$(", i) and not s.startswith("$((", i))):
                i = self.expand(i, [])
            elif pair == "{}" and c == '"':
                i = self.dq(i + 1, [], '"')[0]
            else:
                depth += (c == pair[0]) - (c == pair[1])
                i += 1
                if depth == 0:
                    return i
        raise Doubt("unclosed " + ("((" if pair == "()" else "${"))

    def dq(self, i, buf, stop):
        s, dyn = self.s, False
        while i < len(s):
            c = s[i]
            if stop and c == stop:
                return i + 1, dyn
            if c == "\\" and i + 1 < len(s) and s[i + 1] in '$`"\\\n':
                buf.append(s[i + 1])
                i += 2
            elif c in "$`":
                dyn, i = True, self.expand(i, buf)
            else:
                buf.append(c)
                i += 1
        if stop:
            raise Doubt("unclosed quote")
        return i, dyn

    def heredocs(self, i, pending):
        s = self.s
        for delim, strip, quoted, cmd in pending:
            body = []
            while i < len(s):
                j = s.find("\n", i)
                j = len(s) if j < 0 else j
                line, i = s[i:j], j + 1
                if (line.lstrip("\t") if strip else line) == delim:
                    break
                body.append(line)
            text = "\n".join(body)
            if not quoted:  # unquoted heredoc: $( ) and `` run
                Lexer(text, self.cmds).dq(0, [], None)
            cmd["stdin"].append(text)
        pending.clear()
        return min(i, len(s))

    def lex(self, i, term):
        s, n = self.s, len(self.s)
        cur = self.new(False)
        buf, dyn, inw, q, redir, pending, depth, case = [], False, False, False, None, [], 0, 0

        def word():
            nonlocal buf, dyn, inw, q, redir, case
            if inw:
                text = "".join(buf)
                if redir in ("<<", "<<-"):
                    pending.append((text, redir == "<<-", q, cur))
                elif redir == "<<<":
                    cur["stdin"].append(text)
                elif redir is None:
                    if not q and all(x in SKIP for x, _ in cur["w"]):
                        case += (text == "case") - (text == "esac" and case > 0)
                    cur["w"].append((text, dyn))
                redir = None
            buf, dyn, inw, q = [], False, False, False

        def end(piped):
            nonlocal cur
            word()
            if redir:
                raise Doubt("redirect without target")
            cur = self.new(piped)

        while i < n:
            c, nx = s[i], s[i + 1] if i + 1 < n else ""
            if c == "\\":
                if nx and nx != "\n":
                    buf.append(nx)
                    inw = q = True
                i += 2
            elif c == "'" or (c == "$" and nx == "'"):
                j = i + 1 + (c == "$")
                while j < n and s[j] != "'":
                    j += 2 if c == "$" and s[j] == "\\" else 1
                if j >= n:
                    raise Doubt("unclosed quote")
                raw = s[i + 1 + (c == "$"):j]
                if c == "$":
                    try:
                        raw = raw.encode("latin-1", "backslashreplace").decode("unicode_escape")
                    except UnicodeDecodeError:
                        pass
                buf.append(raw)
                inw = q = True
                i = j + 1
            elif c == '"' or (c == "$" and nx == '"'):
                i, d = self.dq(i + 1 + (c == "$"), buf, '"')
                dyn |= d
                inw = q = True
            elif c in "`$":
                i = self.expand(i, buf)
                dyn = inw = True
            elif c in "<>=" and nx == "(" and not (c == "=" and inw):
                i = self.lex(i + 2, ")")  # process substitution
                buf.append("<(..)")
                dyn = inw = True
            elif c == "#" and not inw:
                j = s.find("\n", i)
                i = n if j < 0 else j
            elif c in " \t":
                word()
                i += 1
            elif c == "\n":
                end(False)
                i = self.heredocs(i + 1, pending)
            elif c in "<>" or (c == "&" and nx == ">"):
                if inw and not q and not dyn and "".join(buf).isdigit():
                    buf, inw = [], False  # fd number: 2>...
                else:
                    word()
                if redir:
                    raise Doubt("stacked redirects")
                redir = next(o for o in ("<<<", "<<-", "&>>", "<<", "<>", "<&", ">>", ">|", ">&", "&>", "<", ">")
                             if s.startswith(o, i))
                i += len(redir)
            elif c == "(" and nx == "(" and not inw and not cur["w"]:
                i = self.balanced(i + 2, 2, "()")  # (( ... ))
            elif c == ")" and not depth and not case:
                if term != ")":
                    raise Doubt("unbalanced )")
                end(False)
                return i + 1
            elif c in "()":
                depth += 1 if c == "(" else -1 if depth else 0
                end(False)
                i += 1
            elif c in ";&|":
                op = s[i:i + 2] if s[i:i + 2] in ("&&", "||", ";;", ";&", "|&") else c
                end(op in ("|", "|&"))
                i += len(op)
            else:
                buf.append(c)
                inw = True
                i += 1
        end(False)
        if term:
            raise Doubt("unclosed $(")
        return n

def unresolved(t):
    return "$" in t or "`" in t

class Scan:
    def __init__(self):
        self.out, self.cd, self.cd_unknown, self.doubts, self.indirect = [], [], False, [], []
        self.vars, self.bad = {}, set()  # literal variables assigned one value in this command

    def res(self, t):
        return VAR.sub(lambda m: self.vars.get(m.group(1) or m.group(2), m.group(0)), t)

    def assign(self, t):
        name, val = t.split("=", 1)
        name, val = name.rstrip("+").split("[")[0], self.res(val)
        if unresolved(val) or "+=" in t or "[" in t.split("=", 1)[0] or name in self.bad \
                or self.vars.get(name, val) != val:
            self.vars.pop(name, None)
            self.bad.add(name)
        else:
            self.vars[name] = val

    def text(self, src, depth=0):
        if depth > 8:
            raise Doubt("nesting too deep")
        cmds = []
        try:
            Lexer(src, cmds).lex(0, None)
        finally:  # commands found before a parse failure are still scanned
            for c in cmds:
                self.cmd(c["w"], c, depth)

    def cmd(self, w, c, depth):
        pre = []
        while w:
            t, d = w[0]
            if not d and t in SKIP | {"function"}:
                w = w[2 if t == "function" else 1:]
            elif ASSIGN.match(t):
                pre.append(t)
                w = w[1:]
            else:
                break
        if not w:  # assignment only: remember it (FOO=1 cmd prefixes are not)
            for t in pre:
                self.assign(t)
            return
        t, d = w[0]
        if d:
            r = self.res(t)
            if unresolved(r):
                self.doubts.append("dynamic command name: {}".format(t[:60]))
            else:  # $CMD -> its value, word-split
                self.text(" ".join([r] + [shlex.quote(self.res(a)) for a, _ in w[1:]]), depth + 1)
            return
        if re.search(r"[*?\[{]", t) and t not in ("[", "[["):
            self.doubts.append("glob command name: {}".format(t[:60]))
            return
        name, args = os.path.basename(t).lower().lstrip("=") or t, w[1:]
        vals = [self.res(a) for a, _ in args]
        if name in ("export", "declare", "local", "readonly", "typeset"):
            for a in vals:
                if ASSIGN.match(a):
                    self.assign(a)
        elif name in ("for", "select", "read"):
            self.bad.update(v for v in vals[:1 if name != "read" else None] if not v.startswith("-"))
            for v in self.bad:
                self.vars.pop(v, None)
        elif name in ("rm", "unlink", "zf_rm", "rmdir", "shred"):
            self.out.append((["unlink" if name == "unlink" else "rm"] + vals, []))
        elif PYCMD.fullmatch(name):  # python script files are read and scanned
            for a in vals:
                if a.endswith(".py") and os.path.isfile(a):
                    try:
                        with open(a, errors="replace") as fh:
                            if PYDEL.search(fh.read(300000)):
                                self.indirect.append("python script removes files: " + a[:80])
                    except OSError:
                        pass
        elif name == "rsync":
            if any(a.startswith("--del") for a in vals):  # deletes inside the destination
                self.out.append((["rm"] + [a for a in vals if not a.startswith("-")][-1:], []))
        elif name == "git":
            k, base = 0, []
            while k < len(vals) and vals[k].startswith("-"):
                if vals[k] in GIT_ARG_OPTS and k + 1 < len(vals):
                    if vals[k] == "-C":
                        base.append((vals[k + 1], unresolved(vals[k + 1])))
                    k += 1
                k += 1
            sub, rest = vals[k] if k < len(vals) else "", vals[k + 1:]
            if sub == "rm":
                self.out.append((["git", "rm"] + rest, base))
            elif sub == "clean":  # a delete unless a pure dry run (-n, -nd, --dry-run; never an -e value)
                free = [a for x, a in enumerate(rest) if rest[x - 1:x] != ["-e"]]
                if not any(a == "--dry-run" or re.fullmatch(r"-[dfiqxX]*n[dfinqxX]*", a) for a in free):
                    self.out.append((["rm"] + ([a for a in free if not a.startswith("-")] or ["."]), base))
        elif name in ("cd", "pushd", "popd", "chdir"):
            ops = [a for a in vals if not (a.startswith("-") and a != "-")]
            if name == "popd" or len(ops) > 1 or (not ops and name == "pushd") or (
                    ops and (unresolved(ops[0]) or ops[0] == "-" or ops[0].startswith("+"))):
                self.cd_unknown = True
            else:
                self.cd.append(ops[0] if ops else "~")
        elif name == "find":
            k, starts = 0, []
            while k < len(vals) and vals[k] in ("-H", "-L", "-P", "-E", "-X", "-s", "-x", "-d", "-f"):
                if vals[k] == "-f" and k + 1 < len(vals):
                    k += 1
                    starts.append(vals[k])
                k += 1
            while k < len(vals) and not vals[k].startswith("-") and vals[k] not in ("(", "!", ")"):
                starts.append(vals[k])
                k += 1
            starts = starts or ["."]
            while k < len(vals):
                if vals[k] == "-delete":
                    self.out.append((["rm"] + starts, []))
                elif vals[k] in ("-exec", "-execdir", "-ok", "-okdir"):
                    j = k + 1
                    while j < len(vals) and vals[j] not in (";", "+"):
                        j += 1
                    inner = [(a.replace("{}", p), x) for a, x in args[k + 1:j] for p in (starts if "{}" in a else [""])]
                    self.cmd(inner, {"stdin": [], "piped": False}, depth + 1)
                    k = j
                k += 1
        elif name in SHELLS:
            k, has_c, has_s = 0, False, False
            while k < len(vals):
                a = vals[k]
                if a in ("-o", "+o", "-O", "+O", "--rcfile", "--init-file"):
                    k += 2
                    continue
                if a in ("-", "--"):
                    k += 1
                    break
                if len(a) < 2 or a[0] not in "-+":
                    break
                if a[0] == "-" and not a.startswith("--"):
                    has_c, has_s = has_c or "c" in a, has_s or "s" in a
                k += 1
            if has_c:
                if k < len(vals):
                    self.text(vals[k], depth + 1)
            elif k >= len(vals) or has_s:  # script from stdin
                for body in c["stdin"]:
                    self.text(body, depth + 1)
                if c["piped"] and not c["stdin"]:
                    self.doubts.append("shell reads commands from a pipe")
        elif name == "eval":
            self.text(" ".join(vals), depth + 1)
        elif name in WRAP:
            opts, k = WRAP[name], 0
            while k < len(vals):
                a = vals[k]
                if name == "env" and ASSIGN.match(a):
                    k += 1
                    continue
                if a == "--":
                    k += 1
                    break
                if name == "command" and a in ("-v", "-V"):
                    return
                if not a.startswith("-") or (a == "-" and name != "env"):
                    break
                x = next((x for x, ch in enumerate(a[1:]) if ch in opts), None) if not a.startswith("--") else None
                if x is not None:
                    val = a[x + 2:]
                    if not val and k + 1 < len(vals):
                        k += 1
                        val = vals[k]
                    if name == "env" and a[x + 1] == "S":  # env -S "rm x"
                        return self.text(" ".join([val] + [shlex.quote(v) for v in vals[k + 1:]]), depth + 1)
                k += 1
            rest = args[k + (name in ("timeout", "gtimeout")):]
            if rest:
                self.cmd(rest, c, depth + 1)


# 1) line-start deletes (kept: the whole line feeds the notes below)
del_lines = [ln.strip().lstrip(";& |") for ln in CMD.splitlines()
             if re.match(r"(rm\s|unlink\s|git\s+rm\b)", ln.strip().lstrip(";& |"))]
# 2) deletes anywhere in the command
sc = Scan()
try:
    sc.text(CMD)
except Exception as exc:  # unclear parse: ask
    sc.doubts.append("command could not be parsed ({})".format(exc))
if "python" in CMD.lower() and PYDEL.search(CMD):
    sc.indirect.append("python code removes files (rmtree/remove/unlink)")
notes = list(sc.doubts) if KW.search(re.sub(r"[\"'\\]", "", CMD)) else []
bases = {os.getcwd()}
for p in sc.cd:  # every cd target is a possible cwd (order ignored, superset)
    bases |= {os.path.abspath(os.path.join(b, os.path.expanduser(p))) for b in bases}
    if len(bases) > 64:
        sc.cd_unknown = True
        break
for words, gitc in sc.out:
    rel = [t for t in words[2 if words[0] == "git" else 1:] if not t.startswith(("-", "/", "~"))]
    roots = bases
    for p, dyn in gitc:
        if dyn:
            notes.append("git -C target unclear: {}".format(p[:60]))
        roots = {os.path.abspath(os.path.join(b, os.path.expanduser(p))) for b in roots}
    if rel and sc.cd_unknown:
        notes.append("cd target unclear, relative delete target: {}".format(rel[0][:60]))
    del_lines.append(shlex.join(words + ([os.path.join(r, t) for r in sorted(roots) for t in rel]
                                         if rel and (sc.cd or gitc) else [])))
if not del_lines and not notes and not sc.indirect:
    sys.exit(0)

home = os.path.expanduser("~")
for line in del_lines:
    if re.search(r"(^|\s)-[a-zA-Z]*[rR][a-zA-Z]*(\s|$)", line) or "--recursive" in line:
        notes.append("recursive delete (-r/-R)")
    # `$?`/`${?}` is an exit status (digits), never a glob; `\$` and `$$` are kept so `\$?`/`$$?` still trip
    if re.search(r"[*?\[]", re.sub(r"\\.|\$\$|\$\{?\?\}?", lambda m: "" if "?" in m.group() and m.group()[0] == "$" else m.group(), line)):
        notes.append("glob/wildcard target")
    try:
        parts = shlex.split(line)
    except ValueError:
        notes.append("command could not be parsed")
        parts = []
    for t in parts:
        if t in ("rm", "unlink", "git") or t.startswith("-"):
            continue
        ap = os.path.abspath(os.path.expanduser(t))
        if ap in ("/", home):
            notes.append("root or home directory itself: {}".format(ap))
        if ap.endswith("/.git") or "/.git/" in ap + "/":
            notes.append("inside .git: {}".format(ap))
        if not (ap + "/").startswith(ROOTS):
            notes.append("outside ~/.claude, the project and temp: {}".format(ap))
msg = "DELETE GUARD: this command deletes files. Confirm the exact paths and that the deletion is intended.\n\nCommand: {}".format(CMD[:200])
extra = sorted(set(notes)) + sorted(set(sc.indirect))
if extra:
    msg += "\n\nATTENTION:\n  " + "\n  ".join(extra)
ask(msg)
PYEOF
RES=$(printf '%s' "$PY" | INPUT="$INPUT" python3 -)
RC=$?
if [ $RC -ne 0 ]; then  # guard crashed or python3 is missing: ask when the input holds a delete word
  if printf '%s' "$INPUT" | sed 's/\\[nt]/ /g' | grep -Eiq '(^|[^[:alnum:]_.-])(rm|rmdir|unlink|zf_rm|shred|-delete|--del[[:alnum:]_-]*|rmtree)([^[:alnum:]_.-]|$)'; then
    printf '%s\n' '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"DELETE GUARD: the guard failed to run (python3 broken or missing) and the command holds a delete word. Confirm before running."}}'
    exit 0
  fi
  exit $RC
fi
[ -n "$RES" ] && printf '%s\n' "$RES"
exit 0
