#!/bin/bash

set -o errexit -o nounset -o xtrace

source ${APP_HOME}/clevercloud/functions.sh

build_sylius
