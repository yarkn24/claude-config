# claude-config

Claude Code configuration for a work machine: global instructions, skills, commands, agents, guard hooks and settings, plus an installer that checks its own result.

## Install
Needs Claude Code, Python 3 and bash (Windows: Git Bash).
1. Get the files: `gh repo clone <owner>/claude-config`, or Code > Download ZIP on this repository's page and extract it.
2. Run `bash claude-config/tools/install_claude.sh`. It copies `claude/` into `~/.claude/`, backs up every file it replaces to `~/.claude/backups/`, merges `settings.json` (package keys win, permission lists and hooks are unioned), installs the 13 recommended Anthropic plugins (`--no-plugins` skips them), and ends with `SELF-CHECK: N PASS, 0 FAIL`. Safe to rerun.
3. Restart Claude Code, then `bash claude-config/tools/install_claude.sh --check-only`. Every line must be PASS.

Windows with PowerShell only: add a `PreToolUse` entry with matcher `PowerShell` and command `powershell -NoProfile -File ~/.claude/hooks/git-guard.ps1`, then run `tests/test_git_guard.ps1`.

## Layout
- `claude/` installs to `~/.claude/`: `CLAUDE.md` (imports `WORK_MACHINE.md`, `RTK.md`, `ABOUT_ME.md`), `settings.json`, `hooks/`, `skills/`, `commands/`, `agents/`, `reference/`, `LEARNED_PATTERNS.md`, `statusline.sh`.
- `tools/install_claude.sh` installer and self-check; `tools/install_repo_guard.sh` puts the local-only git guard (`shared/git-hooks/`) into one repository on request; `tools/prepublish_check.sh` scans the package for personal data, tokens and em dashes.
- `tests/` trip tests for the guards: `bash tests/test_git_guard.sh`, `bash tests/test_git_hooks.sh`, `python3 tests/test_delete_guard.py`, `python3 tests/test_md_rules_skill_scope.py`, `python3 tests/test_opus_concurrency_stale_marker.py`.

## Licenses
Third-party skills keep their licenses: see `LICENSES/` and the `LICENSE` or `NOTICE` file inside each skill folder.
