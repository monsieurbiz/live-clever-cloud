#!/bin/bash -l

set -o errexit -o nounset -o xtrace

source ${APP_HOME}/clevercloud/functions.sh

prepare_s3cfg
download_artifact
prepare_application
