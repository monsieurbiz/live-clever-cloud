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
