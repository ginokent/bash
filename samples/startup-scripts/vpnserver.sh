#!/bin/bash
set -E -e -o pipefail
cd "$(dirname "$0")" || exit 1

# export for func
[ "${LOG_DISABLECOLOR}" ] || enablecolor=true
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

Run sudo curl -LRSs https://djeeno.github.io/bash/samples/systemd/vpnserver.service -o /etc/systemd/system/vpnserver.service
Run sudo systemctl daemon-reload
Run sudo systemctl enable vpnserver
Run sudo systemctl restart vpnserver
