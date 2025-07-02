install: 
# Symfony local proxy - https://symfony.com/doc/current/setup/symfony_server.html
	symfony local:proxy:start
# Create project
	symfony composer create-project --no-scripts sylius/sylius-standard=~2.1.0 apps/sylius
# Docker
	docker compose pull
	docker compose build --pull
	docker compose up -d
# PHP
	cp .php-version apps/sylius/.php-version # See https://docs.sylius.com/the-book/installation/system-requirements
	cp php.ini apps/sylius/php.ini
# Symfony local proxy domains - https://symfony.com/doc/current/setup/symfony_server.html
	(cd apps/sylius && symfony local:proxy:domain:attach sylius)
# Symfony server
	(cd apps/sylius && symfony local:server:start -d)
	(cd apps/sylius && symfony composer install --prefer-dist)
# Doctrine
	(cd apps/sylius && symfony console doctrine:database:drop --if-exists --force)
	(cd apps/sylius && symfony console doctrine:database:create --if-not-exists)
# Symfony commands
	(cd apps/sylius && symfony console doctrine:migr:migr -n)
	(cd apps/sylius && symfony console messenger:setup-transports)
	(cd apps/sylius && symfony console lexik:jwt:generate-keypair --skip-if-exists)
	(cd apps/sylius && symfony console sylius:payment:generate-key -q) # See https://docs.sylius.com/the-customization-guide/customizing-payments/how-to-integrate-a-payment-gateway-as-a-plugin
# Symfony envs
	cp .env.dev apps/sylius/.env.dev
# Theme
	(cd apps/sylius; yarn install) # Node version 20 || 22 - See https://docs.sylius.com/the-book/installation/system-requirements
	(cd apps/sylius; yarn encore prod) # Node version 20 || 22 - See https://docs.sylius.com/the-book/installation/system-requirements
	# Sylius fixtures
	(cd apps/sylius && symfony console sylius:fixtures:load -n)
# Sylius assets
	(cd apps/sylius && symfony console sylius:install:assets)
	(cd apps/sylius && symfony console assets:install --symlink --relative)
.PHONY: install

reset: 
# Symfony local proxy - https://symfony.com/doc/current/setup/symfony_server.html
	(cd apps/sylius && symfony local:proxy:domain:detach sylius)
# Symfony server
	(cd apps/sylius && symfony local:server:stop)
# Docker
	docker compose down --remove-orphans --volumes
# Delete source
	rm -rf apps
.PHONY: reset

# Config
APP_REGION=par
APP_ALIAS=prod
APP_ID=sylius-prod
APP_DOMAIN=sylius.preprod.monsieurbiz.cloud
PHP_FLAVOR=XS
MYSQL_PLAN=dev
CELLAR_PLAN=S
CELLAR_ADDON_NAME=artifacts
CELLAR_BUCKET_NAME=clever-cloud-live
ORG_ID = $(shell cat .organizationId)
PHP_VERSION = $(shell cat .php-version)

cellar:
# Cellar addon - https://www.clever-cloud.com/developers/doc/addons/cellar/
	clever addon create cellar-addon --plan ${CELLAR_PLAN} --org "${ORG_ID}" "artifacts"

setup:
# PHP application - https://www.clever-cloud.com/developers/doc/applications/php/
	clever create --type php --region "${APP_REGION}" --org "${ORG_ID}" --alias ${APP_ALIAS} ${APP_ID}
	clever config -a "${APP_ALIAS}" update --enable-force-https
	clever scale -a "${APP_ALIAS}" --flavor ${PHP_FLAVOR}
# Database - https://www.clever-cloud.com/developers/doc/addons/mysql/
	clever addon create mysql-addon --plan ${MYSQL_PLAN} --org "${ORG_ID}" --link "${APP_ALIAS}" "${APP_ID}-db"
# Buckets - https://www.clever-cloud.com/developers/doc/addons/fs-bucket/
	clever addon create fs-bucket --region "${APP_REGION}" --org "${ORG_ID}" --link "${APP_ALIAS}" "${APP_ID}-fs-media"
	clever addon create fs-bucket --region "${APP_REGION}" --org "${ORG_ID}" --link "${APP_ALIAS}" "${APP_ID}-fs-logs"
	clever addon create fs-bucket --region "${APP_REGION}" --org "${ORG_ID}" --link "${APP_ALIAS}" "${APP_ID}-fs-private"
# Domain - https://www.clever-cloud.com/developers/doc/administrate/domain-names/
	clever domain add "${APP_DOMAIN}" -a "${APP_ALIAS}"
.PHONY: setup

# Setup env vars - https://www.clever-cloud.com/developers/doc/reference/reference-environment-variables/
env:
# Clever Cloud env vars
	clever env --app "${APP_ID}" set CC_PHP_VERSION ${PHP_VERSION}
	clever env --app "${APP_ID}" set CC_FS_BUCKET /apps/sylius/public/media:$$(clever addon env $$(clever addon list -o ${ORG_ID} --format=json | jq -r '.[] | select(.name == "${APP_ID}-fs-media") | .addonId') --format=json | jq -r '.BUCKET_HOST')
	clever env --app "${APP_ID}" set CC_FS_BUCKET_1 /apps/sylius/var/log:$$(clever addon env $$(clever addon list -o ${ORG_ID} --format=json | jq -r '.[] | select(.name == "${APP_ID}-fs-logs") | .addonId') --format=json | jq -r '.BUCKET_HOST')
	clever env --app "${APP_ID}" set CC_FS_BUCKET_2 /apps/sylius/private:$$(clever addon env $$(clever addon list -o ${ORG_ID} --format=json | jq -r '.[] | select(.name == "${APP_ID}-fs-private") | .addonId') --format=json | jq -r '.BUCKET_HOST')
	clever env --app "${APP_ID}" set CC_WEBROOT /apps/sylius/public
	clever env --app "${APP_ID}" set CC_TROUBLESHOOT false
	clever env --app "${APP_ID}" set ENABLE_APCU true # https://www.clever-cloud.com/developers/doc/applications/php/#enable-specific-extensions
	clever env --app "${APP_ID}" set HTTPS on
	clever env --app "${APP_ID}" set MEMORY_LIMIT 256M
# Clever cloud hooks - https://www.clever-cloud.com/developers/doc/develop/build-hooks/
	clever env --app "${APP_ID}" set CC_PRE_BUILD_HOOK ./clevercloud/pre_build_hook.sh
	clever env --app "${APP_ID}" set CC_POST_BUILD_HOOK ./clevercloud/post_build_hook.sh
	clever env --app "${APP_ID}" set CC_PRE_RUN_HOOK ./clevercloud/pre_run_hook.sh
	clever env --app "${APP_ID}" set CC_RUN_SUCCEEDED_HOOK ./clevercloud/run_succeeded_hook.sh
# Clever cloud worker env vars
	clever env --app "${APP_ID}" set CC_WORKER_COMMAND_1 "clevercloud/symfony_console.sh messenger:consume main --time-limit=300 --failure-limit=1 --memory-limit=512M --sleep=5"
	clever env --app "${APP_ID}" set CC_WORKER_RESTART always
	clever env --app "${APP_ID}" set CC_WORKER_RESTART_DELAY 5
# Symfony env vars
	clever env --app "${APP_ID}" set APP_ENV ${APP_ALIAS}
	clever env --app "${APP_ID}" set APP_DEBUG 0
	clever env --app "${APP_ID}" set DATABASE_URL $$(clever env --app "${APP_ID}" | grep MYSQL_ADDON_URI | cut -d"=" -f2 | tr -d '"')
	clever env --app "${APP_ID}" set APP_SECRET "$(shell openssl rand -hex 32)"
# Sylius env vars
	clever env --app "${APP_ID}" set RUN_FIXTURES true
	clever env --app "${APP_ID}" set SYLIUS_FIXTURES_HOSTNAME ${APP_DOMAIN}
	clever env --app "${APP_ID}" set SYLIUS_FIXTURES_SUITE default
# Cellar env vars
	clever env --app "${APP_ID}" set CELLAR_KEY_ID "$$(clever addon env $$(clever addon list -o ${ORG_ID} --format=json | jq -r '.[] | select(.name == "${CELLAR_ADDON_NAME}") | .addonId') --format=json | jq -r '.CELLAR_ADDON_KEY_ID')"
	clever env --app "${APP_ID}" set CELLAR_KEY_SECRET "$$(clever addon env $$(clever addon list -o ${ORG_ID} --format=json | jq -r '.[] | select(.name == "${CELLAR_ADDON_NAME}") | .addonId') --format=json | jq -r '.CELLAR_ADDON_KEY_SECRET')"
	clever env --app "${APP_ID}" set CELLAR_HOST "$$(clever addon env $$(clever addon list -o ${ORG_ID} --format=json | jq -r '.[] | select(.name == "${CELLAR_ADDON_NAME}") | .addonId') --format=json | jq -r '.CELLAR_ADDON_HOST')"
	clever env --app "${APP_ID}" set ARTIFACT_URL "s3://${CELLAR_BUCKET_NAME}/sylius/main-application.tgz"
.PHONY: env

destroy:
# Delete application
	clever delete -a "${APP_ALIAS}" --yes
# Delete database
	clever addon delete "${APP_ID}-db" --yes
# Delete buckets
	clever addon delete "${APP_ID}-fs-media" --yes
	clever addon delete "${APP_ID}-fs-logs" --yes
	clever addon delete "${APP_ID}-fs-private" --yes
.PHONY: destroy
