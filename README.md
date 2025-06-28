# compose-template

This project template uses Terraform and Docker Compose to deploy a compose app with the following capabilities built in out of the box:

* automated volume and database backups using [stack-back](https://github.com/lawndoc/stack-back)
* public access using [Cloudflare Tunnel](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/)
* just-in-time secret injection using [Infisical](https://infisical.com)

Altogether, the template containers use <50MB of memory and <0.5GB of disk space on the container host.

This template requires pre-existing infrastructure to work. See the [cjmay.dev](https://cjmay.dev) for details.

## Using this template

To use this template:

1. Create a new repo from this template. The repo name will become the subdomain for the app, excluding any "compose-" prefix (ex. compose-minecraft -> minecraft.yourdomain.com).
2. Wait for GitHub Actions to deploy the app's infrastructure or [deploy dev infrastructure manually](#local-development).
3. Modify `docker-compose.yaml` to create a compose file with the app containers.
4. Make sure the `traefik` labels are set on the frontend container.
5. Add any additional app secrets to the deployed Infisical project.

---

# *__Replace everything above this line with the app's documentation.__*

## Running the app

### Deployed resources

GitHub Actions will automatically deploy the infrastructure using the provided Terraform code. These resources will be created:

* Ubuntu server with Docker installed
* Backblaze B2 bucket for backups
* Backblaze B2 app key for the bucket
* Cloudflare Tunnel to publish the app
* DNS record pointing to the tunnel
* Infisical project for app secrets
* Infisical secrets to access the above resources

### Compose app startup

After the infrastructure has been deployed, Ansible will configure the Ubuntu server and deploy the compose app on it. __Infisical CLI is used to inject app secrets just-in-time, ensuring the app's secrets never touch the disk on the server** (see snippet below).__ Any manual work done on the Ubuntu server will also require Infisical CLI.

```bash
infisical run --env prod --command "make compose"
```

Ansible handles updates in the same way, gracefully restarting services with Infisical CLI after the update has completed.

** Some secrets may end up in a container's volume on-disk.

## Local development

To intialize a local development environment, follow these steps:

1. Install Terraform and Infisical CLI tools
2. Run `./local-init.sh <infra|app>` and follow the prompts
3. Run `source .env.local`

The `local-init.sh` script assumes you want to use the "dev" environment. If you want to use a different environment locally, make sure to update the `.infisical.json` file that is created during first-time setup, and then re-run `local-init.sh`.

### Infrastructure development

Use the local init script

```bash
./local-init.sh infra
```

You can then deploy the infrastructure with terraform

```bash
make tf-init
make tf-plan
make tf-apply
```

### Ansible or Docker Compose development

Use the local init script

```bash
./local-init.sh app
```

You can then configure the docker host with ansible

```bash
make configure
```

...or deploy the compose app on the docker host

```bash
make compose
```

### Remove local secrets when done

Make sure to remove `.env.local` and log out of Infisical CLI when you are done for the day so secrets don't sit on your development machine.

```bash
make lock
```

## Miscellaneous info

Some design choices were made that are helpful to know when using this template:

* The `local-init.sh` script chooses the deployment environment based on the contents of `.infisical.json` which is initialized the first time `local-init.sh` is run.
* The provided `Makefile` contains various shorthand commands for working with Terraform, Ansible, and Docker Compose. Be aware of the commands and flags being used to prevent unexpected behavior.
* This project uses `stack-back` to backup all container volumes and databases on a default schedule. If the default backup configuration is undesireable, refer to [stack-back's docs](https://stack-back.readthedocs.io) for information on configuring `stack-back` to fine-tune backup settings.
* Git submodules are used within this template to ensure that updates to the submodules are able to easily be pulled in by repos that have cloned this template.