#!/bin/bash
set -Eeu -o pipefail
cd "$(dirname "$0")" || exit 1

ls -dls -- */*
