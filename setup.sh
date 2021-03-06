#!/bin/bash

################################################################################
# WARNING: DO NOT EDIT THIS FILE. EDIT run.sh INSTEAD.
#
# This file auto updates the dashboard builder code prior to running it, then
# runs `run.sh`.
################################################################################

set -e

function absolute_path {
  [[ $1 = /* ]] && echo "$1" || echo "$(pwd)/${1#./}"
}

ROOT_DIRECTORY=$(dirname "$(dirname $(absolute_path "$0"))")
SCRIPT_DIRECTORY=${ROOT_DIRECTORY}/dashboard_box
GSUTIL=${GSUTIL:-"/Users/$USER/google-cloud-sdk/bin/gsutil"}

LOG_FILE="/tmp/flutter.dashboard.output.txt"
echo 'Pulling from git' >$LOG_FILE

(cd $SCRIPT_DIRECTORY; git pull)

echo 'Starting run.sh' >>$LOG_FILE
set +e
(cd $ROOT_DIRECTORY; ROOT_DIRECTORY=$ROOT_DIRECTORY $SCRIPT_DIRECTORY/run.sh 2>&1 >>$LOG_FILE)
set -e

# Upload logs to Google Cloud Storage

if [ -e "$ROOT_DIRECTORY/data/build_cancelled" ]; then
  exit 0;
fi

pushd $ROOT_DIRECTORY/flutter
SHA=$(git rev-parse HEAD)
popd

$GSUTIL cp $LOG_FILE gs://flutter-dashboard/$SHA/output.txt
$GSUTIL -m acl ch -R -g 'google.com:R' gs://flutter-dashboard/$SHA
