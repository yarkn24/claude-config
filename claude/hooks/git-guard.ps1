# git-guard (PreToolUse, PowerShell tool): same rules as git-guard.sh.
# ASKS before commit, push, send-pack, remote, any gh command, and any git command naming
# --no-verify, core.hooksPath or alias. Local-only machine: runs only if the operator asked for
# that exact action in the current message. No writes, no network.
$raw = [Console]::In.ReadToEnd()
$cmd = $raw -replace '\\[ntr]', ' '
$opt = '(([\s]+(-[Cc]|--git-dir|--work-tree|--namespace)[\s]+[^\s]+)|([\s]+--[A-Za-z-]+(=[^\s]+)?)|([\s]+-[A-Za-z]))*'
$b = '(^|[^A-Za-z0-9_.-])'
function Ask($what) {
  $o = @{ hookSpecificOutput = @{ hookEventName = 'PreToolUse'; permissionDecision = 'ask'; permissionDecisionReason = "Local-only machine: $what runs only if the operator asked for this exact action in the current message." } }
  Write-Output ($o | ConvertTo-Json -Compress -Depth 4)
  exit 0
}
if ($cmd -match ($b + 'git(\.exe)?' + $opt + '\s+(push|send-pack|commit|remote)([^A-Za-z0-9_-]|$)')) { Ask 'a git commit, push or remote action' }
if ($cmd -match ($b + 'gh(\.exe)?\s')) { Ask 'a gh command' }
if ($cmd -match ($b + 'git(\.exe)?\s.*(--no-verify|core\.hooksPath|alias\.)')) { Ask 'a git command that skips or redefines hooks or aliases' }
exit 0
