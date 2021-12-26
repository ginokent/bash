#!/usr/bin/env bash
set -Eeou pipefail
if [ ! "${BASH_VERSINFO:-0}" -ge 3 ]; then printf '\033[1;31m%s\033[0m\n' "bash 3.x or later is required" 1>&2; exit 1; fi
# このリポジトリ向け lint

# func
# MIT License Copyright (c) 2021 newtstat https://github.com/newtstat/rec.sh
_recRFC3339() { date "+%FT%T%z" | sed "s/\(..\)$/:\1/"; }
_recEscape() { printf %s "${1:-}" | sed "s/\"/\\\"/g; s/\r/\\\r/g; s/\t/\\\t/g; s/$/\\\n/g" | tr -d "[:cntrl:]" | sed "s/\\\n$/\n/"; }
_recJSON() { _svr="${1:?}" _msg="$(_recEscape "${2:-}")" && shift 2 && unset _fld _val && for a in "$@"; do if [ "${_val:-}" ]; then _fld="${_fld:?}:\"$(_recEscape "${a:-}")\"" && unset _val && continue; fi && _fld="${_fld:-}${_fld:+,}\"${a:?}\"" _val=1; done && [ $(($# % 2)) = 0 ] || _fld="${_fld:?}:\"\"" && printf "{%s}\n" "\"${REC_TIMESTAMP_KEY:=timestamp}\":\"$(_recRFC3339)\",\"${REC_SEVERITY_KEY:=severity}\":\"${_svr:?}\",\"${REC_CALLER_KEY:=caller}\":\"$0\",\"${REC_MESSAGE_KEY:=message}\":\"${_msg:?}\"${_fld:+,}${_fld:-}"; }
_recCmd() { for a in "$@"; do if echo "${a:-}" | grep -Eq "[[:blank:]]"; then printf "'%s' " "${a:-}"; else printf "%s " "${a:-}"; fi; done | sed "s/ $//"; }
RecDefault() { test "${REC_SEVERITY:-0}" -gt 000 2>/dev/null || _recJSON DEFAULT "$@" 1>&2; }
RecDebug() { test "${REC_SEVERITY:-0}" -gt 100 2>/dev/null || _recJSON DEBUG "$@" 1>&2; }
RecInfo() { test "${REC_SEVERITY:-0}" -gt 200 2>/dev/null || _recJSON INFO "$@" 1>&2; }
RecNotice() { test "${REC_SEVERITY:-0}" -gt 300 2>/dev/null || _recJSON NOTICE "$@" 1>&2; }
RecWarning() { test "${REC_SEVERITY:-0}" -gt 400 2>/dev/null || _recJSON WARNING "$@" 1>&2; }
RecError() { test "${REC_SEVERITY:-0}" -gt 500 2>/dev/null || _recJSON ERROR "$@" 1>&2; }
RecCritical() { test "${REC_SEVERITY:-0}" -gt 600 2>/dev/null || _recJSON CRITICAL "$@" 1>&2; }
RecAlert() { test "${REC_SEVERITY:-0}" -gt 700 2>/dev/null || _recJSON ALERT "$@" 1>&2; }
RecEmergency() { test "${REC_SEVERITY:-0}" -gt 800 2>/dev/null || _recJSON EMERGENCY "$@" 1>&2; }
RecExec() { RecInfo "$ $(_recCmd "$@")" && "$@"; }
RecRun() { _dlm='####R#E#C#D#E#L#I#M#I#T#E#R####' _all=$({ _out=$("$@") && _rtn=$? || _rtn=$? && printf "\n%s" "${_dlm:?}${_out:-}" && return ${_rtn:-0}; } 2>&1) && _rtn=$? || _rtn=$? && _dlmno=$(echo "${_all:-}" | sed -n "/${_dlm:?}/=") && _cmd=$(_recCmd "$@") && _stdout=$(echo "${_all:-}" | tail -n +"${_dlmno:-1}" | sed "s/^${_dlm:?}//") && _stderr=$(echo "${_all:-}" | head -n "${_dlmno:-1}" | grep -v "^${_dlm:?}") && RecInfo "$ ${_cmd:-}" command "${_cmd:-}" stdout "${_stdout:-}" stderr "${_stderr:-}" return "${_rtn:-0}" && return ${_rtn:-0}; }

# <<
RecInfo "\"<\" と文字列が隣接すると HTML タグとして解釈される問題があるため、以下コマンドで、ヒアドキュメントの \"<<\" の後ろにスペースを追加するよう置換します。"
RecRun bash -c 'git grep -l "<<[^[:space:]]" | grep -v "lint\.sh" | xargs -I{} perl -pe "s/(<<)([^[:space:]])/\1 \2/g" -i {} || true'

# httpGet
RecInfo "httpGet を更新します。"
# shellcheck disable=SC2016
RecRun bash -c 'git grep -l -E " ##httpGetDoNotRemoveThisComment##" | grep -Ev "^releases/|lint.sh" | xargs -I {} perl -0pe "s@\n.*##httpGetDoNotRemoveThisComment##@\nhttpGet=\"\\\$( { command -v curl 1>/dev/null \\&\\& printf \"curl -fLRSs\"; } || { command -v wget 1>/dev/null \\&\\& printf \"wget -O- -q\"; } )\" \\&\\& export httpGet; [ \"\\\${httpGet:?\"curl or wget are required\"}\" ] || exit 1; [ \"\\\${EnvIsLoaded:-false}\" = true ] || eval \"\\\$(sh -c \"\\\${httpGet} https://newtstat.github.io/bash/common/\")\" || exit 1  ##httpGetDoNotRemoveThisComment##@g" -i {} || true'
