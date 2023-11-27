#!/usr/bin/env bash
# LISENCE: https://github.com/kunitsucom/wg.sh/blob/HEAD/LICENSE
set -Eeu -o pipefail

main() {
  wg_server_host=${WG_SERVER_HOST:-$(curl -Ss checkip.amazonaws.com)}
  wg_server_internal_ip=${WG_SERVER_INTERNAL_IP:-192.168.252.254}
  wg_server_port=${WG_SERVER_PORT:-25252}
  wg_server_nic_name=${WG_SERVER_NIC_NAME:-wg0}
  wg_server_eth_name=${WG_SERVER_ETH_NAME:-eth0}
  wg_server_conf="${WG_CONF_DIR:-.}/${wg_server_nic_name:?}.conf"
  wg_peer_conf="${WG_CONF_DIR:-.}/${wg_server_nic_name:?}_peer_$(TZ=UTC date +%Y%m%dT%H%M%SZ).conf"
  wg_peer_internal_ip=${WG_PEER_INTERNAL_IP:-192.168.252.10}

  if [[ ! -f "${wg_server_conf:?}" ]]; then
    {
      echo "# MEMO: installation command"
      echo "#   sudo apt install -y wireguard"
      echo "#   sudo systemctl enable wg-quick@wg0"
      echo "#   sudo systemctl start wg-quick@wg0"
      echo
      echo "# ================================"
      echo "# ${wg_server_conf:?}"
      echo "# ================================"
      echo "[Interface]"
      echo "# wg server host"
      echo "#Host = ${wg_server_host:?}"
      echo "# wg server private key"
      echo "PrivateKey = $(wg genkey)"
      echo "# wg server internal ip address and cidr"
      echo "Address = ${wg_server_internal_ip:?}/24"
      echo "# wg server mtu"
      echo "MTU = 1380"
      echo "# wg server dns"
      echo "DNS = 1.1.1.1, 1.0.0.1, 8.8.8.8"
      echo "# wg server listen port"
      echo "ListenPort = ${wg_server_port:?}"
      echo "# command wg server post up"
      echo "PostUp = iptables -A FORWARD -i ${wg_server_nic_name:?} -j ACCEPT; iptables -t nat -A POSTROUTING -o ${wg_server_eth_name:?} -j MASQUERADE"
      echo "# command wg server post down"
      echo "PostDown = iptables -D FORWARD -i ${wg_server_nic_name:?} -j ACCEPT; iptables -t nat -D POSTROUTING -o ${wg_server_eth_name:?} -j MASQUERADE"
    } | tee -a "${wg_server_conf:?}" >/dev/null
  fi

  {
    echo "# ================================"
    echo "# ${wg_peer_conf:?}"
    echo "# ================================"
    echo "[Interface]"
    echo "# wg peer private key"
    echo "PrivateKey = $(wg genkey)"
    echo "# wg peer internal ip address and cidr"
    echo "Address = ${wg_peer_internal_ip:?}/24"
    echo "MTU = 1380"
    echo "DNS = 1.1.1.1, 1.0.0.1, 8.8.8.8"
    echo
    echo "[Peer]"
    echo "# wg server public key"
    echo "PublicKey = $(awk '/PrivateKey = / {print $3}' "${wg_server_conf:?}" | head -n 1 | wg pubkey)"
    echo "# wg server preshared key"
    echo "PresharedKey = $(wg genpsk)"
    echo "# cidrs via wg server"
    echo "AllowedIPs = 0.0.0.0/0, ::/0"
    echo "# wg server endpoint"
    echo "Endpoint = $(awk '/Host = / {print $3}' "${wg_server_conf:?}" | head -n 1):$(awk '/ListenPort = / {print $3}' "${wg_server_conf:?}" | head -n 1)"
    echo "# wg server persistent keepalive"
    echo "PersistentKeepalive = 25"
  } | tee -a "${wg_peer_conf:?}" >/dev/null

  {
    echo
    echo "# ================================"
    echo "# for ${wg_peer_conf:?}"
    echo "# ================================"
    echo "[Peer]"
    echo "# wg peer public key"
    echo "PublicKey = $(awk '/PrivateKey = / {print $3}' "${wg_peer_conf:?}" | head -n 1 | wg pubkey)"
    echo "# wg peer preshared key"
    echo "PresharedKey = $(awk '/PresharedKey = / {print $3}' "${wg_peer_conf:?}" | head -n 1)"
    echo "# wg peer internal ip address and cidr"
    echo "AllowedIPs = $(awk '/Address = / {gsub("/.*", "", $3); print $3}' "${wg_peer_conf:?}" | head -n 1)/32"
    echo "# wg peer persistent keepalive"
    echo "PersistentKeepalive = 25"
  } | tee -a "${wg_server_conf:?}" >/dev/null

} && main "$@"
