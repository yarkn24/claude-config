> On this machine `~/.claude/WORK_MACHINE.md` wins: every deletion and every protected-path change is approved by the operator at the prompt (`rm`, `git rm`, `sudo` are `ask` rules).

# File Deletion Procedure

Referenced from `~/.claude/CLAUDE.md` "Maximum Autonomy". Operator, 2026-10-22, verbatim: **"bunu bosver sen, her agenta silme yetkisi ve ama silinecekleri ayri opus review etsin oyle silsin opus medium effortta baksin"** and **"Bana bir daha tamam sil diye sorma"**. Replaces the "tamam sil" gate, the 2026-09-24 manifest path, and the weekly-purge scheduler.

1. **List:** any agent may delete. Before deleting, list each path with its reason.
2. **Review:** dispatch a SEPARATE fresh Agent with `model: opus`, `effort: medium`, role sentence first (path, contents summary, reason only). It reviews each path once and returns APPROVE or REJECT plus one line.
3. **Delete:** delete only APPROVED paths, then prove each is gone (`ls`/`test -e`).
4. **Never ask** the operator "tamam sil". The operator saying "tamam sil" still authorizes an immediate delete.
5. **Record** every deletion (path, reason, verdict, date) in the project's existing `silinecek/MANIFEST.md`, or `~/.claude/logs/deletions.jsonl` when the project has none.
6. **Denied:** if a permission or classifier denies the delete, do not work around it; report it.

Does not cover: the delete-guard hard floors (paths outside its allowed roots, recursive deletes) still go to the operator as a ready-to-run script.
