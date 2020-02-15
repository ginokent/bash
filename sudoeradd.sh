#!/bin/sh
sudoeradd() {(set -e; SDR="${1:?}"; SDRF=/etc/sudoers.d/administrators; ROW="${SDR} ALL=(ALL) NOPASSWD:ALL"; if ! id "${SDR}" 1>/dev/null 2>&1; then sudo useradd -m -s /bin/bash -b /home "${SDR}"; yes "Password.${SDR}" | sudo passwd "${SDR}" 2>/dev/null || true; fi; if ! sudo grep -q "${ROW}" "${SDRF}" 2>/dev/null; then echo "${ROW}" | sudo tee -a "${SDRF}" 1>/dev/null; fi; sudo chmod 0600 "${SDRF}")}
sudoeradd "$@"
