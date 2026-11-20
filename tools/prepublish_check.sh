#!/bin/bash
# Pre-publish check for the package. Fails (exit 1) on: a nested .git, a personal identifier, a token pattern, or U+2014.
# Patterns are assembled from pieces so this file passes its own scan.
# Usage: bash tools/prepublish_check.sh [package-root]   (default: the folder above tools/)
ROOT="${1:-$(cd "$(dirname "$0")/.." && pwd)}"
fail=0
report() { echo "FAIL [$1]"; echo "$2" | head -50; fail=1; }

nested="$(cd "$ROOT" && find . -mindepth 2 \( -name .git -o -name .gitmodules \) 2>/dev/null)"
[ -n "$nested" ] && report "nested .git or .gitmodules (git would record a gitlink and the zipball loses the folder)" "$nested"

names='yark''n24|Yar''kin|Ak''cil|23541''4167|gm''ail\.com|@pro''ton'
hits="$(cd "$ROOT" && grep -rIniE --exclude-dir=.git "$names" . 2>/dev/null)"
[ -n "$hits" ] && report "personal identifier" "$hits"
paths='/Us''ers/|[A-Za-z]:\\Us''ers\\'
hits="$(cd "$ROOT" && grep -rInE --exclude-dir=.git "$paths" . 2>/dev/null)"
[ -n "$hits" ] && report "personal path (case-sensitive)" "$hits"

tokens='gh[pousr]_[A-Za-z0-9]{20,}|github''_pat_[A-Za-z0-9_]{20,}|\bsk-[A-Za-z0-9_-]{8,}|xox[abp]-[A-Za-z0-9-]{8,}|AKIA[0-9A-Z]{16}|Bearer [A-Za-z0-9._-]{20,}|-----BEGIN [A-Z ]*PRIVATE KEY'
hits="$(cd "$ROOT" && grep -rInE --exclude-dir=.git "$tokens" . 2>/dev/null)"
[ -n "$hits" ] && report "token pattern" "$hits"

hits="$(cd "$ROOT" && grep -rInF --exclude-dir=.git "$(printf '\xe2\x80\x94')" . 2>/dev/null)"
[ -n "$hits" ] && report "U+2014 em dash" "$hits"

n="$(cd "$ROOT" && find . -type f -not -path '*/.git/*' | wc -l | tr -d ' ')"
if [ $fail = 0 ]; then echo "PREPUBLISH CHECK PASS ($n files, 0 hits)"; else echo "PREPUBLISH CHECK FAIL"; exit 1; fi
