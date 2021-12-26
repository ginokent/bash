#!/bin/bash
set -Eeou pipefail
cd "$(dirname "$0")" || exit 1

ls -dls -- */*
