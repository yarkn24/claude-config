# How to Commit (only when the operator asks)

This machine is local-only by default. Commit, push, pull request, repository or remote creation happen ONLY when the operator asks for that exact action in the current message. Approval covers that one action; it never carries to later actions or sessions. The git-level guard (`~/.config/git/hooks`) refuses until the variable is set inline on that single command.

## 1. Identity

Use the identity already configured by the firm. Do not change global `user.name` or `user.email`.

```bash
git config user.name; git config user.email
```

## 2. Commit (operator asked for this commit)

```bash
git status
git add <paths>
ALLOW_COMMIT=1 git commit -m "<what changed and why>"
```

Stage named paths, never `git add .`, so unrelated files stay out. Never use `--no-verify`.

## 3. Push (operator asked for this push)

```bash
ALLOW_PUSH=1 git push
```

Set the variable inline on that one command only. Never export it, never persist it.

## 4. Rules that never loosen

- History rewrite and force push never run on firm repositories.
- Never override `core.hooksPath`, never define aliases for these actions.
- Never put a token, credential or client data in a commit message.
- Files over 100MB are blocked by GitHub; keep build output and dependency folders in `.gitignore` before the first commit.
