#!/usr/bin/env bash
set -Eeu -o pipefail

# MIT License Copyright (c) 2021 ginokent https://github.com/rec-logger/rec.sh
# Common
_recRFC3339() { date "+%Y-%m-%dT%H:%M:%S%z" | sed "s/\(..\)$/:\1/"; }
_recCmd() { for a in "$@"; do if echo "${a:-}" | grep -Eq "[[:blank:]]"; then printf "'%s' " "${a:-}"; else printf "%s " "${a:-}"; fi; done | sed "s/ $//"; }
# Color
RecDefault() { test "  ${REC_SEVERITY:-0}" -gt 000 2>/dev/null || echo "$*" | awk "{print   \"$(_recRFC3339) [\\033[0;35m  DEFAULT\\033[0m] \"\$0\"\"}" 1>&2; }
RecDebug() { test "    ${REC_SEVERITY:-0}" -gt 100 2>/dev/null || echo "$*" | awk "{print   \"$(_recRFC3339) [\\033[0;34m    DEBUG\\033[0m] \"\$0\"\"}" 1>&2; }
RecInfo() { test "     ${REC_SEVERITY:-0}" -gt 200 2>/dev/null || echo "$*" | awk "{print   \"$(_recRFC3339) [\\033[0;32m     INFO\\033[0m] \"\$0\"\"}" 1>&2; }
RecNotice() { test "   ${REC_SEVERITY:-0}" -gt 300 2>/dev/null || echo "$*" | awk "{print   \"$(_recRFC3339) [\\033[0;36m   NOTICE\\033[0m] \"\$0\"\"}" 1>&2; }
RecWarning() { test "  ${REC_SEVERITY:-0}" -gt 400 2>/dev/null || echo "$*" | awk "{print   \"$(_recRFC3339) [\\033[0;33m  WARNING\\033[0m] \"\$0\"\"}" 1>&2; }
RecError() { test "    ${REC_SEVERITY:-0}" -gt 500 2>/dev/null || echo "$*" | awk "{print   \"$(_recRFC3339) [\\033[0;31m    ERROR\\033[0m] \"\$0\"\"}" 1>&2; }
RecCritical() { test " ${REC_SEVERITY:-0}" -gt 600 2>/dev/null || echo "$*" | awk "{print \"$(_recRFC3339) [\\033[0;1;31m CRITICAL\\033[0m] \"\$0\"\"}" 1>&2; }
RecAlert() { test "    ${REC_SEVERITY:-0}" -gt 700 2>/dev/null || echo "$*" | awk "{print   \"$(_recRFC3339) [\\033[0;41m    ALERT\\033[0m] \"\$0\"\"}" 1>&2; }
RecEmergency() { test "${REC_SEVERITY:-0}" -gt 800 2>/dev/null || echo "$*" | awk "{print \"$(_recRFC3339) [\\033[0;1;41mEMERGENCY\\033[0m] \"\$0\"\"}" 1>&2; }
RecExec() { RecInfo "$ $(_recCmd "$@")" && "$@"; }
RecRun() { _dlm="####R#E#C#D#E#L#I#M#I#T#E#R####" _all=$({ _out=$("$@") && _rtn=$? || _rtn=$? && printf "\n%s" "${_dlm:?}${_out:-}" && return ${_rtn:-0}; } 2>&1) && _rtn=$? || _rtn=$? && _dlmno=$(echo "${_all:-}" | sed -n "/${_dlm:?}/=") && _cmd=$(_recCmd "$@") && _stdout=$(echo "${_all:-}" | tail -n +"${_dlmno:-1}" | sed "s/^${_dlm:?}//") && _stderr=$(echo "${_all:-}" | head -n "${_dlmno:-1}" | grep -v "^${_dlm:?}") && RecInfo "$ ${_cmd:-}" && { [ -z "${_stdout:-}" ] || RecInfo "${_stdout:?}"; } && { [ -z "${_stderr:-}" ] || RecWarning "${_stderr:?}"; } && return ${_rtn:-0}; }
# export functions for bash
# shellcheck disable=SC3045
echo "${SHELL-}" | grep -q bash$ && export -f _recRFC3339 _recCmd RecDefault RecDebug RecInfo RecWarning RecError RecCritical RecAlert RecEmergency RecExec RecRun

MustFoundCommands() {
  # shellcheck disable=SC2207
  local not_found_commands=($(
    for cmd in "$@"; do
      if ! command -v "${cmd-}" 1>/dev/null; then
        echo "${cmd-}"
      fi
    done
  ))
  if [[ "${#not_found_commands[@]}" -eq 0 ]]; then
    return
  fi
  RecCritical "command not found: ${not_found_commands[*]}"
  exit 127
}

MustFoundCommands apt apt-get dpkg sudo

export DEBIAN_FRONTEND=noninteractive

RecExec sudo -E apt-get update
RecExec sudo -E apt-get install -y curl iptables kmod uidmap
RecExec sudo -E modprobe ip_tables

if ! sudo -E dpkg -l dbus-user-session | grep -Eq ^ii; then
  RecNotice "Install dbus-user-session"
  RecExec sudo -E apt-get install -y dbus-user-session
  RecNotice "Require re-login"
  exit 255
fi

rootless_user=rkeops
install_script="/home/${rootless_user:?}/get.docker.com.rootless.sh"

if [[ ! -d "/home/${rootless_user:?}" ]]; then
  RecExec sudo useradd -m -d "/home/${rootless_user:?}" "${rootless_user:?}"
fi
RecExec sudo curl -fsSL https://get.docker.com/rootless -o "${install_script:?}"
RecExec sudo loginctl enable-linger "${rootless_user:?}"
RecExec sudo -u "${rootless_user:?}" XDG_RUNTIME_DIR="/run/user/$(id -u "${rootless_user:?}")" sh "${install_script:?}"
RecExec sudo -u "${rootless_user:?}" XDG_RUNTIME_DIR="/run/user/$(id -u "${rootless_user:?}")" systemctl --user status docker.service
