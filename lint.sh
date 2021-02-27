#!/usr/bin/env bash
set -E -e -u -o pipefail
if [ ! "${BASH_VERSINFO:-0}" -ge 3 ]; then printf '\033[1;31m%s\033[0m\n' "bash 3.x or later is required" 1>&2; exit 1; fi
# このリポジトリ向け lint

# export for func
[ "${LOG_DISABLECOLOR:-}" ] || export enablecolor=true
export  pipe_debug="awk \"{print \\\"${enablecolor:+\\\\033[0;34m}\$(date +%Y-%m-%dT%H:%M:%S%z) [ debug] \\\"\\\$0\\\"${enablecolor:+\\\\033[0m}\\\"}\" /dev/stdin"
export   pipe_info="awk \"{print \\\"${enablecolor:+\\\\033[0;36m}\$(date +%Y-%m-%dT%H:%M:%S%z) [  info] \\\"\\\$0\\\"${enablecolor:+\\\\033[0m}\\\"}\" /dev/stdin"
export pipe_notice="awk \"{print \\\"${enablecolor:+\\\\033[0;32m}\$(date +%Y-%m-%dT%H:%M:%S%z) [notice] \\\"\\\$0\\\"${enablecolor:+\\\\033[0m}\\\"}\" /dev/stdin"
export   pipe_warn="awk \"{print \\\"${enablecolor:+\\\\033[0;33m}\$(date +%Y-%m-%dT%H:%M:%S%z) [  warn] \\\"\\\$0\\\"${enablecolor:+\\\\033[0m}\\\"}\" /dev/stdin"
export  pipe_error="awk \"{print \\\"${enablecolor:+\\\\033[0;31m}\$(date +%Y-%m-%dT%H:%M:%S%z) [ error] \\\"\\\$0\\\"${enablecolor:+\\\\033[0m}\\\"}\" /dev/stdin"
export   pipe_crit="awk \"{print \\\"${enablecolor:+\\\\033[1;31m}\$(date +%Y-%m-%dT%H:%M:%S%z) [  crit] \\\"\\\$0\\\"${enablecolor:+\\\\033[0m}\\\"}\" /dev/stdin"

# func
export severity="${LOG_SEVERITY:--1}"
Debugln  () { [ "${severity:--1}" -gt 100 ] 2>/dev/null || echo "$*" | bash -c "${pipe_debug:?}"  1>&2; }
Infoln   () { [ "${severity:--1}" -gt 200 ] 2>/dev/null || echo "$*" | bash -c "${pipe_info:?}"   1>&2; }
Noticeln () { [ "${severity:--1}" -gt 300 ] 2>/dev/null || echo "$*" | bash -c "${pipe_notice:?}" 1>&2; }
Warnln   () { [ "${severity:--1}" -gt 400 ] 2>/dev/null || echo "$*" | bash -c "${pipe_warn:?}"   1>&2; }
Errorln  () { [ "${severity:--1}" -gt 500 ] 2>/dev/null || echo "$*" | bash -c "${pipe_error:?}"  1>&2; }
Critln   () { [ "${severity:--1}" -gt 600 ] 2>/dev/null || echo "$*" | bash -c "${pipe_crit:?}"   1>&2; }
Run      () { Debugln "$ $(for s in "$@"; do if echo "$s" | grep -Eq "[[:blank:]]"; then printf "'%s' " "$s"; else printf "%s " "$s"; fi; done)"; "$@"; }

# <<
Infoln "\"<\" と文字列が隣接すると HTML タグとして解釈される問題があるため、以下コマンドで、ヒアドキュメントの \"<<\" の後ろにスペースを追加するよう置換します。"
Run bash -c 'git grep -l "<<[^[:space:]]" | grep -v "lint\.sh" | xargs -I{} perl -pe "s/(<<)([^[:space:]])/\1 \2/g" -i {} || true'

# httpGet
Infoln "httpGet を更新します。"
# shellcheck disable=SC2016
Run bash -c 'git grep -l -E " ##httpGetDoNotRemoveThisComment##" | grep -Ev "^releases/|lint.sh" | xargs -I {} perl -0pe "s@\n.*##httpGetDoNotRemoveThisComment##@\nhttpGet=\"\\\$( { command -v curl 1>/dev/null \\&\\& printf \"curl -fLRSs\"; } || { command -v wget 1>/dev/null \\&\\& printf \"wget -O- -q\"; } )\"; export httpGet; [ \"\\\${httpGet:?\"curl or wget are required\"}\" ] || exit 1; [ \"\\\${EnvIsLoaded:-false}\" = true ] || eval \"\\\$(bash -c \"exec \\\${httpGet} https://djeeno.github.io/bash/common/\")\" || exit 1  ##httpGetDoNotRemoveThisComment##@g" -i {} || true'
