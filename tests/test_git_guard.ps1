# Feeds sample PowerShell tool events to claude/hooks/git-guard.ps1. Expects "ask" or empty output; exits 1 on any FAIL.
$hook = Join-Path $PSScriptRoot '..\claude\hooks\git-guard.ps1'
$fail = 0
function Check($expect, $cmd) {
  $json = (@{ tool_name = 'PowerShell'; tool_input = @{ command = $cmd } } | ConvertTo-Json -Compress)
  $out = ($json | powershell -NoProfile -File $hook) -join ''
  if ($expect -eq 'ask') {
    if ($out -match '"permissionDecision":"ask"') { Write-Output "PASS ask    : $cmd" } else { Write-Output "FAIL (wanted ask): $cmd"; $script:fail = 1 }
  } else {
    if ([string]::IsNullOrEmpty($out)) { Write-Output "PASS empty  : $cmd" } else { Write-Output "FAIL (wanted empty): $cmd"; $script:fail = 1 }
  }
}
foreach ($c in @('git push','git push origin main','git -C . push origin main','git -c push.default=current push','git --no-pager push','cd repo; git push','git.exe push','git commit -m x','git commit --no-verify -m x','git -c core.hooksPath=/dev/null commit -m x','git remote add origin u','gh pr create --fill','gh repo create x','git config alias.p push')) { Check 'ask' $c }
foreach ($c in @('git status','git log --grep push','git diff','ls gh-pages')) { Check 'empty' $c }
if ($fail -eq 0) { Write-Output 'ALL PASS' } else { Write-Output 'FAILURES'; exit 1 }
