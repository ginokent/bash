#!/bin/bash
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

# clear
RecExec sudo -E iptables --flush
RecExec sudo -E iptables --delete-chain

# init
RecExec sudo -E iptables --policy INPUT   DROP
RecExec sudo -E iptables --policy FORWARD DROP
RecExec sudo -E iptables --policy OUTPUT  ACCEPT

# # DROP invalid packets
# RecExec sudo -E iptables --append INPUT --protocol tcp --tcp-flags ALL NONE --jump DROP               # Drop NONE flag ("--tcp-flags ALL NONE" means NONE flag in ALL flags)
# RecExec sudo -E iptables --append INPUT --protocol tcp ! --syn --match state --state NEW --jump DROP  # Drop not syn but new

# loopback interface
RecExec sudo -E iptables --append INPUT --in-interface lo --jump ACCEPT

# ESTABLISHED
RecExec sudo -E iptables --append INPUT --match state --state ESTABLISHED,RELATED --jump ACCEPT

# ICMP
RecExec sudo -E iptables --append INPUT --protocol icmp --jump ACCEPT

# # Internal
# RecExec sudo -E iptables --append INPUT --protocol tcp --match tcp --dport 22 --source 10.0.0.0/8 --jump ACCEPT
# RecExec sudo -E iptables --append INPUT --protocol tcp --match tcp --dport 22 --source 172.16.0.0/12 --jump ACCEPT
# RecExec sudo -E iptables --append INPUT --protocol tcp --match tcp --dport 22 --source 192.168.0.0/16 --jump ACCEPT

# SSH
RecExec sudo -E iptables --append INPUT --protocol tcp --match tcp --dport 22 --jump ACCEPT
RecExec sudo -E iptables --append INPUT --protocol tcp --match tcp --dport 25252 --jump ACCEPT

# HTTP
RecExec sudo -E iptables --append INPUT --protocol tcp --match tcp --dport 80 --jump ACCEPT

# HTTPS
RecExec sudo -E iptables --append INPUT --protocol tcp --match tcp --dport 443 --jump ACCEPT

# SoftEther VPN Server
RecExec sudo -E iptables --append INPUT --protocol tcp --match tcp --dport 500 --jump ACCEPT
RecExec sudo -E iptables --append INPUT --protocol udp --match udp --dport 500 --jump ACCEPT
RecExec sudo -E iptables --append INPUT --protocol tcp --match tcp --dport 1194 --jump ACCEPT
RecExec sudo -E iptables --append INPUT --protocol udp --match udp --dport 1194 --jump ACCEPT
RecExec sudo -E iptables --append INPUT --protocol tcp --match tcp --dport 1701 --jump ACCEPT
RecExec sudo -E iptables --append INPUT --protocol udp --match udp --dport 1701 --jump ACCEPT
RecExec sudo -E iptables --append INPUT --protocol udp --match udp --dport 4500 --jump ACCEPT
RecExec sudo -E iptables --append INPUT --protocol tcp --match tcp --dport 5555 --jump ACCEPT

# LOG
RecExec sudo -E iptables --append INPUT --jump LOG --log-prefix "drop_packet:" 

# # DROP
# RecExec sudo -E iptables -A INPUT -j DROP

# SAVE
export DEBIAN_FRONTEND=noninteractive
RecExec sudo -E apt-get install -qqy iptables-persistent
RecExec sudo -E /etc/init.d/netfilter-persistent save

if [[ ! -x /usr/local/vpnserver/vpnserver ]]; then
  export url="https://github.com/SoftEtherVPN/SoftEtherVPN_Stable/releases/download/v4.38-9760-rtm/softether-vpnserver-v4.38-9760-rtm-2021.08.17-linux-x64-64bit.tar.gz"
  RecExec sudo -E apt-get install -qqy gcc make
  RecExec sudo -E bash -c "mkdir -p ~/tmp && cd ~/tmp && curl -#fLR \"${url:?}\" -o ~/tmp/softether-vpnserver.tar.gz && tar xfz ~/tmp/softether-vpnserver.tar.gz && cd ~/tmp/vpnserver && make && mv ~/tmp/vpnserver /usr/local"
  RecExec sudo -E chown -R root:root /usr/local/vpnserver
  RecExec sudo -E chmod 600 /usr/local/vpnserver/*
  RecExec sudo -E chmod 700 /usr/local/vpnserver/vpncmd
  RecExec sudo -E chmod 700 /usr/local/vpnserver/vpnserver
  
  RecExec sudo -E tee /etc/systemd/system/vpnserver.service <<'EOF'
[Unit]
Description=SoftEther VPN Server
After=network.target network-online.target
#
[Service]
ExecStart=/usr/local/vpnserver/vpnserver start
ExecStop=/usr/local/vpnserver/vpnserver stop
Type=forking
RestartSec=3s
#
[Install]
WantedBy=multi-user.target
EOF

  RecExec sudo -E systemctl daemon-reload
  RecExec sudo -E systemctl enable vpnserver
  RecExec sudo -E systemctl start vpnserver
  RecExec sleep 5
  RecExec sudo -E systemctl status vpnserver

  RecExec sudo -E /usr/local/vpnserver/vpncmd /SERVER localhost /CMD ServerPasswordSet Passw0rd

  RecExec sudo -E tee /usr/local/vpnserver/startup-script <<"EOF"
Hub DEFAULT
SecureNatEnable
UserCreate /GROUP:none /REALNAME:none /NOTE:none vpnuser000
UserPasswordSet vpnuser000 /PASSWORD:vpnuser000password
IPsecEnable /L2TP:yes /L2TPRAW:yes /ETHERIP:yes /PSK:VPNPreSharedKey /DEFAULTHUB:DEFAULT
EOF

  RecExec sudo -E /usr/local/vpnserver/vpncmd /SERVER localhost /PASSWORD:Passw0rd /IN:/usr/local/vpnserver/startup-script
fi
