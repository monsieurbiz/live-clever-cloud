#!/bin/bash -l

set -o errexit -o nounset -o xtrace

function download_artifact() {
  if [ -f "${APP_HOME}/.s3cfg" ]; then
    s3cmd --config="${APP_HOME}/.s3cfg" get "${ARTIFACT_URL}" application.tgz

    return
  fi

  wget -q -O application.tgz "${ARTIFACT_URL}"
}
export -f download_artifact

function prepare_application() {
  tar xvzf application.tgz
  rm -f application.tgz
}
export -f prepare_application

function prepare_s3cfg() {
  # Check if the source file exists and CELLAR_KEY_ID env var exists,and perform the substitution
  if [ -f "${APP_HOME}/s3cfg.dist" ] && [ -n "${CELLAR_KEY_ID:-}" ]; then
    envsubst < "${APP_HOME}/s3cfg.dist" > "${APP_HOME}/.s3cfg"
  fi
}
export -f prepare_s3cfg

function build_sylius() {
  cd ${APP_HOME}/apps/sylius
  php -d memory_limit=-1 ./bin/console sylius:install:assets -v
  php -d memory_limit=-1 ./bin/console doctrine:migr:migr -n -v
  php -d memory_limit=-1 ./bin/console messenger:setup-transports -n -v
  if [ "${RUN_FIXTURES+x}" ] && [ "${RUN_FIXTURES}" == "true" ]; then
    php -d memory_limit=-1 ./bin/console sylius:fixtures:load -n ${SYLIUS_FIXTURES_SUITE} -v
  fi
}
export -f build_sylius

function run_sylius() {
  cd ${APP_HOME}/apps/sylius
  php -d memory_limit=-1 ./bin/console cache:warmup -v
}
export -f run_sylius
