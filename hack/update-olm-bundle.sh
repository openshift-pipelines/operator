#!/usr/bin/env bash
set -e
ENVIRONMENT=${1:-"staging"}
BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$BASEDIR")"

source $BASEDIR/olm-functions.sh

update_bundle_image $ENVIRONMENT
