#!/bin/sh
set -eu
export LANG=C LC_ALL=C

httpGet="$( { command -v curl 1>/dev/null && printf "curl -fLRSs"; } || { command -v wget 1>/dev/null && printf "wget -O- -q"; } )" && export httpGet; [ "${httpGet:?"curl or wget are required"}" ] || exit 1; [ "${EnvIsLoaded:-false}" = true ] || eval "$(sh -c "${httpGet} https://newtstat.github.io/bash/common/")" || exit 1  ##httpGetDoNotRemoveThisComment##

public_keys_http_url="${PUBLIC_KEYS_HTTP_URL:="https://newtstat.github.io/bash/keys"}"
RecNotice "Get public keys"
public_keys=$(RecExec sh -c "${httpGet:?} ${public_keys_http_url:?} | grep ^ssh-")

if [ -z "${public_keys-}" ]; then
  RecCritical "public key not found in ${public_keys_http_url:?}"
  exit 1
fi

if [ -f "$HOME/.ssh/authorized_keys" ]; then
  RecNotice "Append public key to authorized_keys"
  echo "${public_keys}" | while read -r LINE; do
    if ! grep -q "$LINE" "$HOME/.ssh/authorized_keys"; then
      RecExec sh -c "echo \"$LINE\" >>\"$HOME/.ssh/authorized_keys\""
    fi
  done
else
  RecNotice "Generate authorized_keys by public key"
  tmp_random_chars="tmp$(LANG=C LC_ALL=C tr -dc 0-9A-Za-z </dev/urandom | head -c 13 || true)"
  # sudo apt-get install -y openssh-client
  RecExec sh -c "echo | ssh-keygen -t rsa -N \"\" -f \"$HOME/.ssh/${tmp_random_chars}\" 1>/dev/null 2>&1 && rm -f \"$HOME/.ssh/${tmp_random_chars}\" && echo \"${public_keys}\" >\"$HOME/.ssh/${tmp_random_chars}.pub\" && mv -f \"$HOME/.ssh/${tmp_random_chars}.pub\" \"$HOME/.ssh/authorized_keys\""
fi

RecNotice "Content of ~/.ssh/authorized_keys:"
RecNotice "$(cat "$HOME/.ssh/authorized_keys")"
