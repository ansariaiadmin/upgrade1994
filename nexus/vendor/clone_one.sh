#!/usr/bin/env bash
n="$1"; d="vendor/git/${n//\//_}"
[ -d "$d/.git" ] && exit 0
if GIT_TERMINAL_PROMPT=0 timeout 240 git clone --depth 1 --single-branch --quiet "https://github.com/$n" "$d" 2>>logs/clone_err.log; then
  echo "OK $n" >> logs/clone_status.log
else
  rm -rf "$d"; echo "FAIL $n" >> logs/clone_fail.log
fi
