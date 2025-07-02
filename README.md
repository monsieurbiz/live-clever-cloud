# Live Sylius <> Clever Cloud

How to setup and deploy a Sylius project on Clever Cloud.

Simpler version of the [Sylius Setup](https://github.com/monsieurbiz/sylius-setup)

## Pre-requisites

- [Composer](https://getcomposer.org/)
- [Docker](https://www.docker.com/)
- [Symfony CLI](https://symfony.com/download)
- [Symfony Local Proxy](https://symfony.com/doc/current/setup/symfony_cli.html#setting-up-the-local-proxy)
- [Clever Cloud CLI](https://www.clever-cloud.com/developers/doc/cli/)

## Setup

### Local

Run `make install`.
You can use `make reset` to reset the local environment.

### Pipeline

You need to create the following secrets in your Github repository

- `CELLAR_ENDPOINT`: Host of the cellar service
- `CELLAR_BUCKET`: The name of your bucket in the cellar service
- `CELLAR_ACCESS_KEY` : Access key for the cellar service
- `CELLAR_SECRET_KEY` : Secret key for the cellar service

If you don't have cellar to store your artifacts, you can create one on Clever Cloud.

```bash
make cellar
```

Before running this command be sure you created a file named `.organizationId` containing your Clever Cloud organization ID.

### Clever Cloud

Create a file containing your Clever Cloud organization ID:
```bash
echo "your-organization-id" > .organizationId
```

To set up the application and the addons on Clever Cloud, run:
```bash
make setup
```

You can use `make destroy` to delete the application and its addons.

To setup all the environment variables, run:
```bash
make env
```

Then you can deploy your application with:
```bash
make deploy
```
