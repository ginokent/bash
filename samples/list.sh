#!/bin/bash
set -E -e -o pipefail
cd "$(dirname "$0")" || exit 1

ls -dls -- */*
