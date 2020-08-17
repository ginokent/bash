#!/bin/bash
set -E -e -o pipefail

cd "$(dirname "$0")" || exit 1

VERSION=v0.1.0
URL_BASE=djeeno.github.io/sh

copy_and_overwrite () {
  rm -rf ./"${1:?}" || true
  cp -a ../"${1:?}" .
  find "${1:?}" -type f -print0 | xargs -I{} perl -pe "s|(${URL_BASE:?})/|\1/${VERSION:?}/|g" -i {}
}

for dir in bashrc common direnv git; do
  copy_and_overwrite "${dir:?}"
done
