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

waits() { _i=0 && while [ "$1" -gt "$_i" ]; do sleep 1 && if [ "$#" -ge 2 ]; then printf "%s" "${2:-}"; fi && _i=$((_i + 1)); done && echo "${3:-}"; }
echo "${SHELL-}" | grep -q bash$ && export -f waits

export DEBIAN_FRONTEND=noninteractive

# common
RecExec sudo -E bash -c "printf 'Passw0rdR00t\nPassw0rdR00t\n' | passwd"
RecExec sudo -E bash -c "curl --tlsv1.2 -fLRSs https://raw.githubusercontent.com/versenv/versenv/HEAD/install.sh | VERSENV_SCRIPTS=fzf VERSENV_PATH=/usr/bin bash"
[[ -e /root/.bash_profile ]] || RecExec sudo -E tee /root/.bash_profile <<"EOF"
# bashrc
[[ ! -r ~/.bashrc ]] || source ~/.bashrc
# history
export HISTSIZE=100000
histori() {
  READLINE_LINE=$(HISTTIMEFORMAT='' history | awk "{a[i++]=\$0}END{for(j=i-1;j>=0;j--)print a[j]}" | sed 's/^[[:blank:]]*[0-9]*[[:blank:]]*//' | fzf --cycle --exact --extended -i --no-mouse --no-sort)
  READLINE_POINT=${#READLINE_LINE}
} && [[ -t 0 ]] && bind -x '"\C-r":histori'
# alias
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias ls='ls --color=auto'
alias l='ls -F'
alias la='ls -A'
alias ll='ls -alF'
alias crontab='crontab -i'
alias fzf='fzf --cycle --exact --extended -i --no-mouse --no-sort'
EOF
RecExec sudo -E tee -a /root/.bash_history <<"EOF"
curl -fLRSs -w '\n' https://domains.google.com/checkip
curl -fLRSs https://checkip.amazonaws.com
less /etc/systemd/system/vpnserver.service
vim /etc/systemd/system/vpnserver.service
systemctl daemon-reload
systemctl enable vpnserver
systemctl start vpnserver
systemctl status vpnserver
/usr/local/vpnserver/vpncmd /SERVER localhost /PASSWORD:Passw0rd
EOF

# clear
RecExec sudo -E iptables --flush
RecExec sudo -E iptables --delete-chain

# init
RecExec sudo -E iptables --policy INPUT ACCEPT
RecExec sudo -E iptables --policy FORWARD ACCEPT
RecExec sudo -E iptables --policy OUTPUT ACCEPT

# Stealth Scan
RecExec sudo -E iptables --new STEALTH_SCAN
RecExec sudo -E iptables --append STEALTH_SCAN --jump LOG --log-prefix "stealth_scan_attack: "
RecExec sudo -E iptables --append STEALTH_SCAN --jump DROP
#
RecExec sudo -E iptables --append INPUT --protocol tcp --tcp-flags SYN,ACK SYN,ACK --match state --state NEW --jump STEALTH_SCAN
RecExec sudo -E iptables --append INPUT --protocol tcp --tcp-flags ALL NONE --jump STEALTH_SCAN # Drop NONE flag ("--tcp-flags ALL NONE" means NONE flag in ALL flags)
#
RecExec sudo -E iptables --append INPUT --protocol tcp --tcp-flags SYN,FIN SYN,FIN --jump STEALTH_SCAN
RecExec sudo -E iptables --append INPUT --protocol tcp --tcp-flags SYN,RST SYN,RST --jump STEALTH_SCAN
RecExec sudo -E iptables --append INPUT --protocol tcp --tcp-flags ALL SYN,RST,ACK,FIN,URG --jump STEALTH_SCAN
#
RecExec sudo -E iptables --append INPUT --protocol tcp --tcp-flags FIN,RST FIN,RST --jump STEALTH_SCAN
RecExec sudo -E iptables --append INPUT --protocol tcp --tcp-flags ACK,FIN FIN --jump STEALTH_SCAN
RecExec sudo -E iptables --append INPUT --protocol tcp --tcp-flags ACK,PSH PSH --jump STEALTH_SCAN
RecExec sudo -E iptables --append INPUT --protocol tcp --tcp-flags ACK,URG URG --jump STEALTH_SCAN

# Fragment
RecExec sudo -E iptables --append INPUT --fragment --jump LOG --log-prefix "fragment_packet: "
RecExec sudo -E iptables --append INPUT --fragment --jump DROP

# Ping of Death
RecExec sudo -E iptables --new PING_OF_DEATH
RecExec sudo -E iptables --append PING_OF_DEATH --protocol icmp --icmp-type echo-request --match hashlimit --hashlimit 1/s --hashlimit-burst 10 --hashlimit-htable-expire 300000 --hashlimit-mode srcip --hashlimit-name t_PING_OF_DEATH -j RETURN
RecExec sudo -E iptables --append PING_OF_DEATH --jump LOG --log-prefix "ping_of_death_attack: "
RecExec sudo -E iptables --append PING_OF_DEATH --jump DROP
RecExec sudo -E iptables --append INPUT --protocol icmp --icmp-type echo-request -j PING_OF_DEATH

# SYN Flood Attack
RecExec sudo -E iptables --new SYN_FLOOD
RecExec sudo -E iptables --append SYN_FLOOD --protocol tcp --syn --match hashlimit --hashlimit 200/s --hashlimit-burst 3 --hashlimit-htable-expire 300000 --hashlimit-mode srcip --hashlimit-name t_SYN_FLOOD --jump RETURN
RecExec sudo -E iptables --append SYN_FLOOD --jump LOG --log-prefix "syn_flood_attack: "
RecExec sudo -E iptables --append SYN_FLOOD --jump DROP
RecExec sudo -E iptables --append INPUT --protocol tcp --syn --jump SYN_FLOOD

# HTTP DoS/DDoS Attack
HTTP=80,443
RecExec sudo -E iptables --new HTTP_DOS
RecExec sudo -E iptables --append HTTP_DOS --protocol tcp --match multiport --dports $HTTP --match hashlimit --hashlimit 1/s --hashlimit-burst 100 --hashlimit-htable-expire 300000 --hashlimit-mode srcip --hashlimit-name t_HTTP_DOS --jump RETURN
RecExec sudo -E iptables --append HTTP_DOS --jump LOG --log-prefix "http_dos_attack: "
RecExec sudo -E iptables --append HTTP_DOS --jump DROP
RecExec sudo -E iptables --append INPUT --protocol tcp --match multiport --dports $HTTP --jump HTTP_DOS

# IDENT port probe
IDENT=113
RecExec sudo -E iptables --append INPUT --protocol tcp --match multiport --dports $IDENT --jump REJECT --reject-with tcp-reset

# SSH Brute Force
SSH=22,25252
RecExec sudo -E iptables --append INPUT --protocol tcp --syn --match multiport --dports $SSH --match recent --name ssh_attack --set
RecExec sudo -E iptables --append INPUT --protocol tcp --syn --match multiport --dports $SSH --match recent --name ssh_attack --rcheck --seconds 60 --hitcount 3 --jump LOG --log-prefix "ssh_brute_force: "
RecExec sudo -E iptables --append INPUT --protocol tcp --syn --match multiport --dports $SSH --match recent --name ssh_attack --rcheck --seconds 60 --hitcount 3 --jump REJECT --reject-with tcp-reset

# Drop not syn but new
RecExec sudo -E iptables --append INPUT --protocol tcp ! --syn --match state --state NEW --jump DROP

# Accept loopback interface
RecExec sudo -E iptables --append INPUT --in-interface lo --jump ACCEPT

# Accept ESTABLISHED
RecExec sudo -E iptables --append INPUT --match state --state ESTABLISHED,RELATED --jump ACCEPT

# Accept ICMP
RecExec sudo -E iptables --append INPUT --protocol icmp --jump ACCEPT

# # Internal
# RecExec sudo -E iptables --append INPUT --protocol tcp --match tcp --dport 22 --source 10.0.0.0/8 --jump ACCEPT
# RecExec sudo -E iptables --append INPUT --protocol tcp --match tcp --dport 22 --source 172.16.0.0/12 --jump ACCEPT
# RecExec sudo -E iptables --append INPUT --protocol tcp --match tcp --dport 22 --source 192.168.0.0/16 --jump ACCEPT

# SSH
RecExec sudo -E iptables --append INPUT --protocol tcp --match multiport --dport 22,25252 --jump ACCEPT

# HTTP,HTTPS
RecExec sudo -E iptables --append INPUT --protocol tcp --match multiport --dport 80,443 --jump ACCEPT

# SoftEther VPN Server
RecExec sudo -E iptables --append INPUT --protocol tcp --match multiport --dport 500,1194,1701,5555 --jump ACCEPT
RecExec sudo -E iptables --append INPUT --protocol udp --match multiport --dport 500,1194,1701,4500 --jump ACCEPT

# DROP
RecExec sudo -E iptables --append INPUT --jump LOG --log-prefix "drop_packet:"
RecExec sudo -E iptables --append INPUT --jump DROP
RecExec sudo -E iptables --append FORWARD --jump DROP

# SAVE
if [[ ! -e /etc/init.d/netfilter-persistent ]]; then
  RecExec sudo -E apt-get update -qqy
  RecExec sudo -E apt-get install -qqy iptables-persistent
fi
RecExec sudo -E /etc/init.d/netfilter-persistent save

if [[ ! -e /usr/local/vpnserver ]] || [[ "${VPNSERVER_REINSTALL:-false}" = true ]]; then
  export SERVICE_FILE=/etc/systemd/system/vpnserver.service
  # clean up
  if [[ -f "${SERVICE_FILE:?}" ]]; then
    RecExec sudo -E systemctl daemon-reload
    RecExec sudo -E systemctl stop vpnserver || true
    RecExec sudo -E systemctl disable vpnserver || true
    RecExec sudo -E rm -f "${SERVICE_FILE:?}" || true
  fi
  RecExec sudo -E rm -rf /usr/local/vpnserver
  # download and install
  export url="https://github.com/SoftEtherVPN/SoftEtherVPN_Stable/releases/download/v4.38-9760-rtm/softether-vpnserver-v4.38-9760-rtm-2021.08.17-linux-x64-64bit.tar.gz"
  RecExec sudo -E apt-get update -qqy
  RecExec sudo -E apt-get install -qqy bridge-utils gcc make
  RecExec sudo -E bash -c "mkdir -p ~/tmp && cd ~/tmp && curl -#fLR \"${url:?}\" -o ~/tmp/softether-vpnserver.tar.gz && tar xfz ~/tmp/softether-vpnserver.tar.gz && cd ~/tmp/vpnserver && make && mv ~/tmp/vpnserver /usr/local && chown -R root:root /usr/local/vpnserver && chmod 700 /usr/local/vpnserver && chmod 600 /usr/local/vpnserver/* && chmod 700 /usr/local/vpnserver/vpncmd && chmod 700 /usr/local/vpnserver/vpnserver"
  # setup systemd
  RecExec sudo -E tee "${SERVICE_FILE:?}" <<EOF
[Unit]
Description=SoftEther VPN Server
Wants=network-online.target
After=network-online.target
ConditionPathExists=!/usr/local/vpnserver/do_not_run
#
[Service]
WorkingDirectory=/usr/local/vpnserver
ExecStartPre=sh -c 'echo 1 > /proc/sys/net/ipv4/ip_forward'
ExecStart=/usr/local/vpnserver/vpnserver start
## NOTE: If promiscuous mode can be enabled, uncomment the following.
#ExecStartPost=/bin/sh -c "/sbin/ip a | grep -Eq '[0-9]+:.br0: .+' || /sbin/brctl addbr br0"
#ExecStartPost=/bin/sleep 4
#ExecStartPost=/bin/sh -c "/sbin/ip a | grep -Eq '[0-9]+:.tap_vpnserver: .+ br0' || /sbin/brctl addif br0 tap_vpnserver"
#ExecStartPost=/sbin/ip link set dev br0 promisc on
#ExecStartPost=/sbin/ip link set dev br0 up
ExecStop=/usr/local/vpnserver/vpnserver stop
Type=forking
KillMode=control-group
Restart=always
RestartSec=4s
StartLimitInterval=10s
StartLimitBurst=5
#
PrivateTmp=yes
ProtectHome=yes
ProtectSystem=full
ReadOnlyDirectories=/
ReadWriteDirectories=-/usr/local/vpnserver
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_BROADCAST CAP_NET_RAW CAP_SYS_NICE CAP_SYS_ADMIN CAP_SETUID
#
[Install]
WantedBy=multi-user.target
EOF
  RecExec sudo -E systemctl daemon-reload
  RecExec sudo -E systemctl enable vpnserver
  RecExec sudo -E systemctl start vpnserver
  waits 8 .
  RecExec sudo -E systemctl status vpnserver | cat
  # setup vpnserver
  RecExec sudo -E /usr/local/vpnserver/vpncmd /SERVER localhost /CMD ServerPasswordSet Passw0rd | logger -i -t vpncmd -s 2>&1
  RecExec sudo -E /bin/sh -c "/sbin/ip a | grep -Eq [0-9]+:.br0 || /sbin/brctl addbr br0"
  ## NOTE: If promiscuous mode can be enabled, append the following to startup-script.
  #BridgeCreate DEFAULT /DEVICE:vpnserver /TAP:yes
  RecExec sudo -E tee /usr/local/vpnserver/vpnserver-startup-script <<"EOF"
Hub DEFAULT
SecureNatEnable
UserCreate /GROUP:none /REALNAME:none /NOTE:none vpnuser000
UserPasswordSet vpnuser000 /PASSWORD:vpnuser000password
IPsecEnable /L2TP:yes /L2TPRAW:no /ETHERIP:yes /PSK:VPNPreSharedKey /DEFAULTHUB:DEFAULT
EOF
  RecExec sudo -E /usr/local/vpnserver/vpncmd /SERVER localhost /PASSWORD:Passw0rd /IN:/usr/local/vpnserver/vpnserver-startup-script | logger -i -t vpncmd -s 2>&1
fi
