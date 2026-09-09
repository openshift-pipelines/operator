#!/usr/bin/env bash
set -e
BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$BASEDIR")"

FILE=$ROOT_DIR/olm/release-stage.txt
FILE_STAGE=$(cat $FILE)
STAGE=${1:-$FILE_STAGE}

case "$STAGE" in
  "devel"|"staging"|"production")
    ;;
  *)
    echo "Invalid selection!"
    exit 1
    ;;
esac

if [[ "$STAGE" != "$FILE_STAGE" ]]; then
  echo "Updating release-stage.txt to $STAGE"
  echo "$STAGE" > $FILE
fi

ENVIRONMENT=$STAGE

source $BASEDIR/olm-functions.sh
update_bundle_image $ENVIRONMENT
