#!/usr/bin/env bash
BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$BASEDIR")"

source $BASEDIR/olm-functions.sh

update_olm_version
