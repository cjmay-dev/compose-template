# compose-app-template

## How to use this template

*__If this is your first time using this template__*, you'll need to follow the [first time setup instructions](#first-time-setup) to create the required "common secrets" project in Infisical. *__This only needs to be done once__*, and then all subsequent templates will use the same common secrets project.

To use this template:

* fork this repo and give it a name that will become the subdomain for your app
* modify [`docker-compose.yaml`] to create a compose file with your app containers
* make sure the `stack-back` and `traefik` labels are set on your new containers
* wait for GitHub Actions to deploy the app's infrastructure or [deploy manually](#deploying-infrastructure-manually)
* add the secrets for your app containers to the deployed Infisical project

Read [Template Info](#template-info) for more details.

*__After forking this template, replace all the contents above this line with your app's documentation.__*

---

## App deployment

### Deploy compose app

Because the app's secrets are stored in an Infisical project, [Infisical CLI](https://infisical.com/docs/cli/overview) is needed to deploy the compose app. The `infisical run` command will inject these secrets just-in-time, ensuring they never touch the disk on the server.

```bash
infisical run --env prod --command "make compose" # explicitly pulls and builds containers before deploying
```

---

# Template Info

This app's template uses Terraform and Docker Compose to deploy a compose app with the following capabilities built in out of the box:

* automated volume and container backups using [stack-back](https://github.com/lawndoc/stack-back)
* public access using [Cloudflare Tunnel](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/)
* secure secret management using [Infisical](https://infisical.com)

Altogether, the template containers use <50MB of memory and <0.5GB of disk space on your container host.

## Infrastructure deployment

### Automated infrastructure deployment

GitHub Actions will automatically deploy your infrastructure using the provided Terraform code. These resources will be created:

* Ubuntu server with Docker installed
* Backblaze B2 bucket for backups
* Backblaze B2 app key for the bucket
* Cloudflare Tunnel to publish the app
* DNS record pointing to the tunnel
* Infisical project for app secrets
* Infisical secrets to access the above resources

### Deploying infrastructure manually

If you prefer to run the Terraform code manually, disable the GitHub Action and follow these steps:

Set environment variables

```bash
cp terraform.env.template terraform.env
vim terraform.env # set variables as described above
source terraform.env
```

Use the makefile to deploy the instrastrucure with Terraform

```bash
make terraform
```

## First time setup

This template requires pre-existing infrastructure to work. See the [cjmay.dev](https://cjmay.dev) for details.