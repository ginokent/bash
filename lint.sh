#!/usr/bin/env bash
set -e -E -o pipefail
# このリポジトリ向け lint

# check bash version
if ! test "${BASH_VERSINFO[0]}" -ge 3; then
  printf '\033[1;31m%s\033[0m\n' "bash 3.x or later is required" 1>&2
  exit 1
fi

# 関数 export
export  pipe_debug="awk \"{print \\\"\\\\033[00m\$(date +%Y-%m-%dT%H:%M:%S%z) [  debug] \\\"\\\$0\\\"\\\\033[0m\\\"}\" /dev/stdin 1>&2"
export pipe_notice="awk \"{print \\\"\\\\033[01m\$(date +%Y-%m-%dT%H:%M:%S%z) [ notice] \\\"\\\$0\\\"\\\\033[0m\\\"}\" /dev/stdin 1>&2"
export  pipe_error="awk \"{print \\\"\\\\033[31m\$(date +%Y-%m-%dT%H:%M:%S%z) [  error] \\\"\\\$0\\\"\\\\033[0m\\\"}\" /dev/stdin 1>&2"
export     pipe_ok="awk \"{print \\\"\\\\033[32m\$(date +%Y-%m-%dT%H:%M:%S%z) [     ok] \\\"\\\$0\\\"\\\\033[0m\\\"}\" /dev/stdin 1>&2"
export   pipe_warn="awk \"{print \\\"\\\\033[33m\$(date +%Y-%m-%dT%H:%M:%S%z) [warning] \\\"\\\$0\\\"\\\\033[0m\\\"}\" /dev/stdin 1>&2"
export   pipe_info="awk \"{print \\\"\\\\033[34m\$(date +%Y-%m-%dT%H:%M:%S%z) [   info] \\\"\\\$0\\\"\\\\033[0m\\\"}\" /dev/stdin 1>&2"

echo "\"<\" と文字列が隣接すると HTML タグとして解釈される問題。以下コマンドで、ヒアドキュメントの \"<<\" の後ろにスペースを追加するよう置換する。" | sh -c "${pipe_info:?}"
echo '$ git grep -l "<<[^[:space:]]" | grep -v "lint\.sh" | xargs -I{} perl -pe "s/(<<)([^[:space:]])/\1 \2/g" -i {}' | tee /dev/stderr | sed "s/^\$ //" | bash



# memo
# git grep -l "##HttpGet##" | xargs -I{} perl -0pe 's@\n.*##HttpGet##@\nhttpGet="\$( { command -v curl 1>/dev/null \&\& printf "curl -LRsS "; } || { command -v wget 1>/dev/null \&\& printf "wget -qO- "; } )"; export httpGet; [ "\${httpGet:?"curl or wget are required"}" ] || exit 1; [ "\${envIsLoaded:-false}" = true ] || eval "\$(sh -c "exec \${httpGet} https://djeeno.github.io/bash/common/")" || exit 1 ##httpGet##@g' -i {}
