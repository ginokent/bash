#!/bin/sh
set -e
export LANG=C LC_ALL=C

export http_get; http_get="$( { command -v curl 1>/dev/null && printf "curl -fLRsS "; } || { command -v wget 1>/dev/null && printf "wget -qO- "; } )"
[ "${http_get:?"curl or wget are required to run this script"}" ] || exit 1

printf "\033[34m$(TZ=Asia/Tokyo date +"%Y-%m-%dT%H:%M:%S+09:00") [   info] %s\033[0m\n" "env:"
printf "\033[34m$(TZ=Asia/Tokyo date +"%Y-%m-%dT%H:%M:%S+09:00") [   info] %s\033[0m\n" "  PUBLIC_KEYS_HTTP_URL: ${PUBLIC_KEYS_HTTP_URL:-USE_DEFAULT}"
public_keys_http_url="${PUBLIC_KEYS_HTTP_URL:="https://djeeno.github.io/sh/keys"}"

public_keys=$(${http_get} "${public_keys_http_url}" | grep ^ssh-)
test -n "${public_keys:?"public key not found in ${public_keys_http_url}"}" || exit 1

if [ -f "$HOME/.ssh/authorized_keys" ]; then
  echo "${public_keys}" | while read -r LINE; do
    if ! grep -q "$LINE" "$HOME/.ssh/authorized_keys"; then
      echo "$LINE" >>"$HOME/.ssh/authorized_keys"
    fi
  done
else
  tmp_random_chars="tmp$(LANG=C LC_ALL=C tr -dc 0-9A-Za-z </dev/urandom | head -c 13 || true)"
  echo | ssh-keygen -t rsa -N "" -f "$HOME/.ssh/${tmp_random_chars}" 1>/dev/null 2>&1 \
    && rm -f "$HOME/.ssh/${tmp_random_chars}" \
    && echo "${public_keys}" >"$HOME/.ssh/${tmp_random_chars}.pub" \
    && mv -f "$HOME/.ssh/${tmp_random_chars}.pub" "$HOME/.ssh/authorized_keys"
fi

printf "\033[34m$(TZ=Asia/Tokyo date +"%Y-%m-%dT%H:%M:%S+09:00") [   info] %s\033[0m\n" "==> $HOME/.ssh/authorized_keys <=="
cat "$HOME/.ssh/authorized_keys"
