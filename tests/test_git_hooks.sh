#!/bin/bash
# Exercises tools/install_repo_guard.sh and shared/git-hooks in TEMP repos with a TEMP HOME and TEMP system/global git config.
# Never sets or reads the real core.hooksPath for writing; compares it before and after. Removes only its own mktemp directory.
HERE="$(cd "$(dirname "$0")" && pwd)"
INSTALL="$HERE/../tools/install_repo_guard.sh"
REAL_BEFORE="$(git config --show-origin --get-all core.hooksPath 2>&1)"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
body() {
  export HOME="$T/home" GIT_CONFIG_GLOBAL="$T/gitconfig" GIT_CONFIG_SYSTEM="$T/sysconfig"
  mkdir -p "$HOME"; : > "$GIT_CONFIG_SYSTEM"
  git config --global user.name tester; git config --global user.email tester@example.invalid
  expect() { # name want(0=success,1=fail,N=exact rc) command...
    local name="$1" want="$2"; shift 2
    "$@" >"$T/out" 2>"$T/err"; local rc=$?
    if { [ "$want" = 0 ] && [ $rc -eq 0 ]; } || { [ "$want" = 1 ] && [ $rc -ne 0 ]; } || { [ "$want" != 0 ] && [ "$want" != 1 ] && [ $rc -eq "$want" ]; }; then echo "PASS: $name (rc=$rc)"; else echo "FAIL: $name (rc=$rc)"; fi
  }
  mkrepo() { git init -q -b main "$1"; git -C "$1" remote add origin "$T/remote.git"; echo a > "$1/f"; git -C "$1" add f; }
  git init -q --bare "$T/remote.git"

  # 1. plain repo
  mkrepo "$T/r1"
  expect "install into a plain repo" 0 bash "$INSTALL" "$T/r1"
  cd "$T/r1"
  expect "commit without ALLOW_COMMIT is refused" 1 git commit -q -m one
  echo "  message: $(head -1 "$T/err")"
  expect "commit with ALLOW_COMMIT=1 succeeds" 0 env ALLOW_COMMIT=1 git commit -q -m one
  expect "push without ALLOW_PUSH is refused" 1 git push -q origin main
  expect "push with ALLOW_PUSH=1 succeeds" 0 env ALLOW_PUSH=1 git push -q origin main
  expect "second install is a no-op" 0 bash "$INSTALL" "$T/r1"
  grep -q "already installed" "$T/out" && echo "PASS: second install reports already installed" || { echo "FAIL: second install message" ; }
  [ -z "$(git config --global --get core.hooksPath)$(git config --get core.hooksPath)" ] && echo "PASS: no core.hooksPath set in global or local scope" || { echo "FAIL: core.hooksPath was set" ; }

  # 2. repo with its own hooks: pre-commit chained, commit-msg untouched and still running
  mkrepo "$T/r2"; cd "$T/r2"
  printf '#!/bin/sh\nexit 1\n' > .git/hooks/pre-commit
  printf '#!/bin/sh\ntouch "%s/commit-msg-ran"\n' "$T" > .git/hooks/commit-msg
  chmod +x .git/hooks/pre-commit .git/hooks/commit-msg
  expect "install over an existing pre-commit" 0 bash "$INSTALL" "$T/r2"
  [ -x .git/hooks/pre-commit.local ] && echo "PASS: previous pre-commit saved as pre-commit.local" || { echo "FAIL: pre-commit.local missing" ; }
  expect "repo's own failing pre-commit still runs (chained) with ALLOW_COMMIT=1" 1 env ALLOW_COMMIT=1 git commit -q -m two
  printf '#!/bin/sh\nexit 0\n' > .git/hooks/pre-commit.local
  expect "commit passes once the chained hook passes" 0 env ALLOW_COMMIT=1 git commit -q -m two
  [ -e "$T/commit-msg-ran" ] && echo "PASS: repo's commit-msg hook still runs (not disabled)" || { echo "FAIL: commit-msg hook did not run" ; }
  expect "--remove restores the previous hook" 0 bash "$INSTALL" --remove "$T/r2"
  grep -q "exit 0" .git/hooks/pre-commit && ! grep -q "for-work local-only guard" .git/hooks/pre-commit && echo "PASS: previous pre-commit restored" || { echo "FAIL: restore" ; }

  # 3. hooksPath at every scope: refuse (rc 3), change nothing
  for scope in global system local; do
    mkrepo "$T/r3$scope"; cd "$T/r3$scope"
    case $scope in
      global) git config --global core.hooksPath "$T/it-hooks" ;;
      system) git config --file "$GIT_CONFIG_SYSTEM" core.hooksPath "$T/it-hooks" ;;
      local)  git config --local core.hooksPath "$T/it-hooks" ;;
    esac
    expect "hooksPath set at $scope scope: install refuses with rc 3" 3 bash "$INSTALL" "$T/r3$scope"
    grep -q "core.hooksPath" "$T/err" && echo "PASS: $scope scope reported on stderr" || { echo "FAIL: $scope scope not reported" ; }
    [ ! -e .git/hooks/pre-commit ] && [ ! -e .git/hooks/pre-push ] && echo "PASS: $scope scope: no hook written" || { echo "FAIL: $scope scope wrote a hook" ; }
    case $scope in
      global) git config --global --unset core.hooksPath ;;
      system) git config --file "$GIT_CONFIG_SYSTEM" --unset core.hooksPath ;;
    esac
  done

  # 4. not a repository
  expect "non-repository path is rejected with rc 2" 2 bash "$INSTALL" "$T/home"
}
(body) | tee "$T/log"
exit_code=0; grep -q '^FAIL' "$T/log" && exit_code=1
REAL_AFTER="$(git config --show-origin --get-all core.hooksPath 2>&1)"
[ "$REAL_BEFORE" = "$REAL_AFTER" ] && echo "PASS: real core.hooksPath unchanged (before == after)" || { echo "FAIL: real core.hooksPath changed"; exit_code=1; }
echo "  real core.hooksPath before/after: [${REAL_BEFORE:-empty}] [${REAL_AFTER:-empty}]"
[ "$exit_code" = 0 ] && echo "ALL PASS" || { echo "FAILURES"; exit 1; }
