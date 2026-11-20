# Spec-Driven Development (GitHub Spec-Kit)

Referenced from `~/.claude/CLAUDE.md` section "Spec-Driven Development". Full original detail below.

For any multi-file feature or significant new module, prefer this workflow before touching code:

1. `/speckit.specify <description>`: writes `spec.md` (requirements, user stories, acceptance criteria)
2. `/speckit.plan`: writes `plan.md` (technical architecture derived from the spec)
3. `/speckit.tasks`: writes `tasks.md` (dependency-ordered implementation checklist)
4. `/speckit.implement`: executes tasks from `tasks.md` one by one

**Use when:** new features, significant refactors, anything where written requirements prevent wasted work.
**Skip when:** single-file bug fixes, trivial changes, or an existing spec already covers the work.
