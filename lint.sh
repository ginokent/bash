#!/usr/bin/env bash
set -E -e -o pipefail -u
if [ ! "${BASH_VERSINFO:-0}" -ge 3 ]; then printf '\033[1;31m%s\033[0m\n' "bash 3.x or later is required" 1>&2; exit 1; fi
# このリポジトリ向け lint

# func
RFC3339      () { date "+%FT%T%z" | sed "s/\(..\)\(..\)$/\1:\2/"; }
RecJSONL     () { unset _jsonl _vflg && for a in "$@"; do if [ "${_vflg-}" ]; then _jsonl="${_jsonl:?}:\"$(printf %s "${a-}" | sed "s/\"/\\\\\"/g; s/$/\\\\n/g" | tr -d "[:cntrl:]" | sed "s/\\\\n$/\n/")\"" && unset _vflg && continue; fi && _jsonl="${_jsonl-}${_jsonl:+,}\"${a:?}\"" _vflg=1; done && [ $(($# % 2)) = 0 ] || _jsonl="${_jsonl:?}:\"\"" && printf "{%s}\n" "${_jsonl:?}"; }
_recLog      () { _lvl="${1-}" _msg="${2-}" && shift 2 && RecJSONL timestamp "$(RFC3339)" severity "${_lvl:?}" caller "$0" message "${_msg-}" "$@" 1>&2; }
RecDEFAULT   () { test "${REC_SEVERITY:-0}" -gt  -1 2>/dev/null || _recLog DEFAULT   "$@"; }
RecDEBUG     () { test "${REC_SEVERITY:-0}" -gt 100 2>/dev/null || _recLog DEBUG     "$@"; }
RecINFO      () { test "${REC_SEVERITY:-0}" -gt 200 2>/dev/null || _recLog INFO      "$@"; }
RecNOTICE    () { test "${REC_SEVERITY:-0}" -gt 300 2>/dev/null || _recLog NOTICE    "$@"; }
RecWARNING   () { test "${REC_SEVERITY:-0}" -gt 400 2>/dev/null || _recLog WARNING   "$@"; }
RecERROR     () { test "${REC_SEVERITY:-0}" -gt 500 2>/dev/null || _recLog ERROR     "$@"; }
RecCRITICAL  () { test "${REC_SEVERITY:-0}" -gt 600 2>/dev/null || _recLog CRITICAL  "$@"; }
RecALERT     () { test "${REC_SEVERITY:-0}" -gt 700 2>/dev/null || _recLog ALERT     "$@"; }
RecEMERGENCY () { test "${REC_SEVERITY:-0}" -gt 800 2>/dev/null || _recLog EMERGENCY "$@"; }
RecRun       () { RecDEBUG "$ $(for a in "$@"; do if echo "$a" | grep -Eq "[[:blank:]]"; then printf "'%s' " "$a"; else printf "%s " "$a"; fi; done | sed "s/ $//")"; "$@"; }
RecRun      () { _drt='####D#E#L#I#M#I#T#E#R####' && _all=$({ _result=$("$@") && _rtn=$? || _rtn=$? && echo "${_drt:?}${_result-}" && return ${_rtn:-0}; } 2>&1) && _rtn=$? || _rtn=$? && _lno=$(echo "${_all-}" | sed -n "/${_drt:?}/=") && RecDEBUG "$ $(for a in "$@"; do if echo "$a" | grep -Eq "[[:blank:]]"; then printf "'%s' " "$a"; else printf "%s " "$a"; fi; done | sed "s/ $//")" stdout "$(echo "${_all-}" | tail -n +"${_lno:?}" | sed "s/^${_drt:?}//")" stderr "$(echo "${_all-}" | head -n "${_lno:?}" | grep -v "^${_drt:?}")" && return ${_rtn:-0}; }

# <<
RecINFO "\"<\" と文字列が隣接すると HTML タグとして解釈される問題があるため、以下コマンドで、ヒアドキュメントの \"<<\" の後ろにスペースを追加するよう置換します。"
RecRun bash -c 'git grep -l "<<[^[:space:]]" | grep -v "lint\.sh" | xargs -I{} perl -pe "s/(<<)([^[:space:]])/\1 \2/g" -i {} || true'

# httpGet
RecINFO "httpGet を更新します。"
# shellcheck disable=SC2016
RecRun bash -c 'git grep -l -E " ##httpGetDoNotRemoveThisComment##" | grep -Ev "^releases/|lint.sh" | xargs -I {} perl -0pe "s@\n.*##httpGetDoNotRemoveThisComment##@\nhttpGet=\"\\\$( { command -v curl 1>/dev/null \\&\\& printf \"curl -fLRSs\"; } || { command -v wget 1>/dev/null \\&\\& printf \"wget -O- -q\"; } )\" \\&\\& export httpGet; [ \"\\\${httpGet:?\"curl or wget are required\"}\" ] || exit 1; [ \"\\\${EnvIsLoaded:-false}\" = true ] || eval \"\\\$(sh -c \"\\\${httpGet} https://newtstat.github.io/bash/common/\")\" || exit 1  ##httpGetDoNotRemoveThisComment##@g" -i {} || true'
