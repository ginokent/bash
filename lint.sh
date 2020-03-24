#!/usr/bin/env bash
set -E -o pipefail
# このリポジトリ向け lint

# check bash version
if ! test "${BASH_VERSINFO[0]}" -ge 3; then
  printf '\033[1;31m%s\033[0m\n' "bash 3.x or later is required" 1>&2
  exit 1
fi

# 関数 export
stderrPipeDebug ()  { awk '{print "\033[00m'"$(date +%Y-%m-%dT%H:%M:%S%z)"' [  debug] "$0"\033[0m"}' /dev/stdin 1>&2; } && export -f stderrPipeDebug
stderrPipeNotice () { awk '{print "\033[01m'"$(date +%Y-%m-%dT%H:%M:%S%z)"' [ notice] "$0"\033[0m"}' /dev/stdin 1>&2; } && export -f stderrPipeNotice
stderrPipeError ()  { awk '{print "\033[31m'"$(date +%Y-%m-%dT%H:%M:%S%z)"' [  error] "$0"\033[0m"}' /dev/stdin 1>&2; } && export -f stderrPipeError
stderrPipeOK ()     { awk '{print "\033[32m'"$(date +%Y-%m-%dT%H:%M:%S%z)"' [     ok] "$0"\033[0m"}' /dev/stdin 1>&2; } && export -f stderrPipeOK
stderrPipeWarn ()   { awk '{print "\033[33m'"$(date +%Y-%m-%dT%H:%M:%S%z)"' [warning] "$0"\033[0m"}' /dev/stdin 1>&2; } && export -f stderrPipeWarn
stderrPipeInfo ()   { awk '{print "\033[34m'"$(date +%Y-%m-%dT%H:%M:%S%z)"' [   info] "$0"\033[0m"}' /dev/stdin 1>&2; } && export -f stderrPipeInfo

echo "\"<\" と文字列が隣接すると HTML タグとして解釈される問題。以下コマンドで、ヒアドキュメントの \"<<\" の後ろにスペースを追加するよう置換する。" | stderrPipeInfo
echo '$ git grep -l "<<[^[:space:]]" | grep -v "lint\.sh" | xargs -I{} perl -pe "s/(<<)([^[:space:]])/\1 \2/g" -i {}' | tee /dev/stderr | sed "s/^\$ //" | bash
