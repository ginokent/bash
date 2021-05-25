#!/bin/bash
set -E -e -o pipefail

cd "$(dirname "$0")" || exit 1

VERSION=$(basename "$(cd "$(dirname "$0")"; pwd)")
URL_BASE=djeeno.github.io/bash
GIT_REPOSITORY_ROOT=$(git rev-parse --show-toplevel)

copy_and_overwrite () {
  rm -rf "${PWD:?}/${1:?}" || true
  cp -a "${GIT_REPOSITORY_ROOT:?}/${1:?}" .
  # shellcheck disable=SC2038
  find "${1:?}" -type f | xargs -I{} perl -pe "s|(${URL_BASE:?})/|\1/releases/${VERSION:?}/|g" -i {}
}

for dir in asdf bashrc brew common direnv git peco; do
  copy_and_overwrite "${dir:?}"
done
