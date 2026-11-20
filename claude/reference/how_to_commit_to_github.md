# HOW TO MAKE A COMMIT SHOW UP ON GITHUB

## 1. SET YOUR IDENTITY (ONCE PER MACHINE)

Get your GitHub user ID:

```bash
gh api user --jq '"id=\(.id)  login=\(.login)"'
```

Set the identity using that ID:

```bash
git config --global user.name "<login>"
git config --global user.email "<id>+<login>@users.noreply.github.com"
```

Confirm both are filled:

```bash
git config --global user.name; git config --global user.email
```

Empty output here means git invents `y@<hostname>` per machine and GitHub credits nobody.

## 2. CONNECT THE REPO TO GITHUB (ONCE PER REPO)

Check for a remote:

```bash
git remote -v
```

No output means nothing was ever pushed. Create the repo and connect it:

```bash
gh repo create <name> --private --source=. --remote=origin
```

Repo already exists on GitHub:

```bash
git remote add origin https://github.com/<login>/<name>.git
```

## 3. COMMIT

```bash
git status
git add <paths>
git commit -m "<what changed and why>"
```

Stage named paths, never `git add .`, so unrelated dirty files stay out.

## 4. PUSH

Commits stay local. Never push; push only on explicit operator request.

## 5. VERIFY IT COUNTED

```bash
gh api repos/<login>/<name>/commits/main --jq '.author.login'
```

Your own login means GitHub credited you. `null` means the commit email does not match your account: go to step 6.

## 6. FIX COMMITS ALREADY PUSHED WITH THE WRONG EMAIL

List the broken addresses:

```bash
git log --format='%ae' | sort | uniq -c
```

Write a mailmap, one line per broken address:

```bash
printf 'NEW_NAME <NEW_EMAIL> <OLD_EMAIL>\n' > /tmp/mailmap.txt
```

Rewrite in a throwaway clone, never in the working repo, so uncommitted files survive:

```bash
git clone --no-local <repo-path> /tmp/rewrite-clone
cd /tmp/rewrite-clone
git filter-repo --mailmap /tmp/mailmap.txt
```

Confirm the rewrite changed identity and nothing else:

```bash
git log --format='%ae' | sort | uniq -c
git rev-parse main^{tree}
```

The tree hash must equal the original's tree hash. Different hash means content changed: stop.

Only on explicit operator request; default is local commits, never push.

Push the corrected history:

```bash
git remote add origin https://github.com/<login>/<name>.git
git push origin +main:main
```

Point the working repo at the new history without touching your files:

```bash
cd <repo-path>
git fetch origin
git reset --soft origin/main
```

`--soft` only. `--hard` deletes every uncommitted change.

## 7. BEFORE ANY FORCE PUSH

Only on explicit operator request; default is local commits, never push.

Pin whatever the remote branch currently holds:

```bash
git push origin refs/remotes/origin/main:refs/heads/backup-<date>
```

Force push after that overwrites nothing that is not recoverable.

## PRIVATE REPOS

Commits in a private repo appear on the profile contribution graph only when GitHub Settings has "Include private contributions on my profile" enabled, and then only as an unnamed block. Inside the repo they always show with your avatar.

## LIMITS

GitHub blocks any file over 100MB and warns over 50MB. Keep `venv/`, `node_modules/`, and build output in `.gitignore` before the first commit; removing them later leaves the blobs in history.
