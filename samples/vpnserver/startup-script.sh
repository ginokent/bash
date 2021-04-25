#!/bin/bash
set -E -e -o pipefail
cd "$(dirname "$0")" || exit 1
export LOG_DISABLECOLOR=true

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

# install vpnserver
Run sudo curl -LRSs https://djeeno.github.io/bash/samples/systemd/vpnserver.service -o /etc/systemd/system/vpnserver.service
Run sudo systemctl daemon-reload
Run sudo systemctl enable vpnserver
Run sudo systemctl restart vpnserver

# INIT
Run iptables --flush INPUT
Run iptables --policy INPUT ACCEPT

# DROP invalid packets
Run iptables --append INPUT --protocol tcp --tcp-flags ALL NONE --jump DROP               # Drop NONE flag ("--tcp-flags ALL NONE" means NONE flag in ALL flags)
Run iptables --append INPUT --protocol tcp ! --syn --match state --state NEW --jump DROP  # Drop not syn but new

# ESTABLISHED
Run iptables --append INPUT --match state --state ESTABLISHED,RELATED --jump ACCEPT

# Internal
Run iptables --append INPUT --protocol tcp --match tcp --dport 22 --source 10.0.0.0/8 --jump ACCEPT
Run iptables --append INPUT --protocol tcp --match tcp --dport 22 --source 172.16.0.0/12 --jump ACCEPT
Run iptables --append INPUT --protocol tcp --match tcp --dport 22 --source 192.168.0.0/16 --jump ACCEPT

# SSH
Run iptables --append INPUT --protocol tcp --match tcp --dport 22 --jump ACCEPT

# HTTP
Run iptables --append INPUT --protocol tcp --match tcp --dport 80 --jump ACCEPT

# HTTPS
Run iptables --append INPUT --protocol tcp --match tcp --dport 443 --jump ACCEPT

# SoftEther VPN Server
Run iptables --append INPUT --protocol udp --match udp --dport 500 --jump ACCEPT
Run iptables --append INPUT --protocol udp --match udp --dport 1194 --jump ACCEPT
Run iptables --append INPUT --protocol tcp --match tcp --dport 1701 --jump ACCEPT
Run iptables --append INPUT --protocol udp --match udp --dport 4500 --jump ACCEPT
Run iptables --append INPUT --protocol tcp --match tcp --dport 5555 --jump ACCEPT

# ICMP
Run iptables -A INPUT --protocol icmp --jump ACCEPT

# loopback interface
Run iptables -A INPUT --in-interface lo --jump ACCEPT

# LOG
#iptables -A INPUT -j LOG --log-prefix 'drop_packet: '

# DROP
Run iptables -A INPUT -j DROP

# SAVE
if grep -q "=Ubuntu" /etc/lsb-release 2>/dev/null; then
  export DEBIAN_FRONTEND=noninteractive
  Run apt-get install -y iptables-persistent
  Run /etc/init.d/netfilter-persistent save
fi
