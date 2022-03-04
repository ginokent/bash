#!/bin/sh
set -eu
export LANG=C LC_ALL=C

httpGet="$( { command -v curl 1>/dev/null && printf "curl -fLRSs"; } || { command -v wget 1>/dev/null && printf "wget -O- -q"; } )" && export httpGet; [ "${httpGet:?"curl or wget are required"}" ] || exit 1

# MIT License Copyright (c) 2021 newtstat https://github.com/newtstat/rec.sh
# Common
_recRFC3339() { date "+%Y-%m-%dT%H:%M:%S%z" | sed "s/\(..\)$/:\1/"; }
_recCmd() { for a in "$@"; do if echo "${a:-}" | grep -Eq "[[:blank:]]"; then printf "'%s' " "${a:-}"; else printf "%s " "${a:-}"; fi; done | sed "s/ $//"; }
# Color
RecDefault() { test "${REC_SEVERITY:-0  }" -gt 000 2>/dev/null || echo "$*" | awk "{print   \"$(_recRFC3339) [\\033[0;35m  DEFAULT\\033[0m] \"\$0\"\"}" 1>&2; }
RecDebug() { test "${REC_SEVERITY:-0    }" -gt 100 2>/dev/null || echo "$*" | awk "{print   \"$(_recRFC3339) [\\033[0;34m    DEBUG\\033[0m] \"\$0\"\"}" 1>&2; }
RecInfo() { test "${REC_SEVERITY:-0     }" -gt 200 2>/dev/null || echo "$*" | awk "{print   \"$(_recRFC3339) [\\033[0;32m     INFO\\033[0m] \"\$0\"\"}" 1>&2; }
RecNotice() { test "${REC_SEVERITY:-0   }" -gt 300 2>/dev/null || echo "$*" | awk "{print   \"$(_recRFC3339) [\\033[0;36m   NOTICE\\033[0m] \"\$0\"\"}" 1>&2; }
RecWarning() { test "${REC_SEVERITY:-0  }" -gt 400 2>/dev/null || echo "$*" | awk "{print   \"$(_recRFC3339) [\\033[0;33m  WARNING\\033[0m] \"\$0\"\"}" 1>&2; }
RecError() { test "${REC_SEVERITY:-0    }" -gt 500 2>/dev/null || echo "$*" | awk "{print   \"$(_recRFC3339) [\\033[0;31m    ERROR\\033[0m] \"\$0\"\"}" 1>&2; }
RecCritical() { test "${REC_SEVERITY:-0 }" -gt 600 2>/dev/null || echo "$*" | awk "{print \"$(_recRFC3339) [\\033[0;1;31m CRITICAL\\033[0m] \"\$0\"\"}" 1>&2; }
RecAlert() { test "${REC_SEVERITY:-0    }" -gt 700 2>/dev/null || echo "$*" | awk "{print   \"$(_recRFC3339) [\\033[0;41m    ALERT\\033[0m] \"\$0\"\"}" 1>&2; }
RecEmergency() { test "${REC_SEVERITY:-0}" -gt 800 2>/dev/null || echo "$*" | awk "{print \"$(_recRFC3339) [\\033[0;1;41mEMERGENCY\\033[0m] \"\$0\"\"}" 1>&2; }
RecExec() { RecInfo "$ $(_recCmd "$@")" && "$@"; }
RecRun() { _dlm='####R#E#C#D#E#L#I#M#I#T#E#R####' _all=$({ _out=$("$@") && _rtn=$? || _rtn=$? && printf "\n%s" "${_dlm:?}${_out:-}" && return ${_rtn:-0}; } 2>&1) && _rtn=$? || _rtn=$? && _dlmno=$(echo "${_all:-}" | sed -n "/${_dlm:?}/=") && _cmd=$(_recCmd "$@") && _stdout=$(echo "${_all:-}" | tail -n +"${_dlmno:-1}" | sed "s/^${_dlm:?}//") && _stderr=$(echo "${_all:-}" | head -n "${_dlmno:-1}" | grep -v "^${_dlm:?}") && RecInfo "$ ${_cmd:-}" && RecInfo "${_stdout:-}" && { [ -z "${_stderr:-}" ] || RecWarning "${_stderr:-}"; } && return ${_rtn:-0}; }

public_keys_http_url="${PUBLIC_KEYS_HTTP_URL:="https://newtstat.github.io/bash/keys"}"
RecNotice "Get public keys"
public_keys=$(RecExec sh -c "${httpGet:?} ${public_keys_http_url:?} | grep ^ssh-")

if [ -z "${public_keys-}" ]; then
  RecCritical "public key not found in ${public_keys_http_url:?}"
  exit 1
fi

if [ -f ~/.ssh/authorized_keys ]; then
  RecNotice "Append public key to authorized_keys"
  echo "${public_keys}" | while read -r LINE; do
    if ! grep -q "$LINE" ~/.ssh/authorized_keys; then
      RecExec sh -c "echo \"$LINE\" >> ~/.ssh/authorized_keys"
    fi
  done
else
  RecNotice "Generate authorized_keys by public key"
  tmp_random_chars="tmp$(LANG=C LC_ALL=C tr -dc 0-9A-Za-z </dev/urandom | head -c 13 || true)"
  # sudo apt-get install -y openssh-client
  RecExec sh -c "echo | ssh-keygen -t rsa -N \"\" -f ~/.ssh/${tmp_random_chars} 1>/dev/null 2>&1 && rm -f ~/.ssh/${tmp_random_chars} && echo \"${public_keys}\" > ~/.ssh/${tmp_random_chars}.pub && mv -f ~/.ssh/${tmp_random_chars}.pub ~/.ssh/authorized_keys"
fi

RecNotice "Content of authorized_keys:"
RecNotice "$(cat ~/.ssh/authorized_keys)"
