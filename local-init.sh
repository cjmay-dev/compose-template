#!/bin/bash

set -e

if [ -z "$1" ]; then
  echo "Usage: $0 <infra|app>"
  echo "  infra: Initialize local infrastructure development environment"
  echo "  app: Initialize local application development environment"
  exit 1
fi

if [ $1 = "infra" ]; then
  if ! terraform --version > /dev/null 2>&1; then
    echo "Terraform CLI is not installed. Please install it first."
    exit 1
  fi
fi

if ! infisical --version > /dev/null 2>&1; then
  echo "Infisical CLI is not installed. Please install it first."
  exit 1
fi 

infisical token  # prompts login or does nothing

if [ $1 = "infra" ]; then
  echo -e "Initializing local infrastructure development environment...\n"
  if [ ! -f .infisical.json ] || [ "$(cat .infisical_workspace)" != "infra" ]; then
    echo "Setting Infisical project... Please select the common secrets project."
    infisical init
    echo "infra" > .infisical_workspace
  fi
elif [ $1 = "app" ]; then
  echo -e "Initializing local application development environment...\n"
  if [ ! -f .infisical.json ] || [ "$(cat .infisical_workspace)" != "app" ]; then
    echo "Setting Infisical project... Please select the application secrets project."
    infisical init
    echo "app" > .infisical_workspace
  fi
else
  echo "Invalid argument: $1"
  echo "Usage: $0 <infra|app>"
  exit 1
fi

if [ "$(jq -r '.defaultEnvironment' .infisical.json)" = "" ]; then
  # assume the local environment is "dev"
  jq '.defaultEnvironment="dev"' .infisical.json > /tmp/infisical.$$.json \
    && mv /tmp/infisical.$$.json .infisical.json
  echo -e "\nInfisical initialized with default environment 'dev'."
  echo "Manually edit .infisical.json to change the default environment."
  echo "Re-run this script if you change the environment."
fi

infisical secrets --plain --recursive > .env.local 2> /dev/null

# wrap values with single quotes to handle multi-line values
tmp=.env.local.tmp
: > "$tmp"
key=""
buffer=""
while IFS= read -r line; do
  if [[ $line =~ ^([A-Z_][A-Z0-9_]*)=(.*) ]]; then
    if [[ -n $key ]]; then
      esc=${buffer//\'/\\\'}
      printf "'%s'\n" "$esc" >> "$tmp"
    fi
    key=${BASH_REMATCH[1]}
    buffer=${BASH_REMATCH[2]}
    printf '%s=' "$key" >> "$tmp"
  else
    buffer+=$'\n'"$line"
  fi
done < .env.local
if [[ -n $key ]]; then
  esc=${buffer//\'/\\\'}
  printf "'%s'\n" "$esc" >> "$tmp"
fi
mv "$tmp" .env.local

chmod 600 .env.local
sed -i -E '/^[A-Z_][A-Z0-9_]*=/ s/^/export /' .env.local
source .env.local

if [ $1 = "infra" ]; then
  if ! curl -k --silent --head $PROXMOX_VE_ENDPOINT > /dev/null; then
    echo "Error: Cannot reach PVE at $PROXMOX_VE_ENDPOINT"
    echo "Please connect to the Tailnet and try again."
    exit 1
  fi

  export TF_VAR_INFISICAL_PROJECT_SLUG=$INFISICAL_COMMON_SECRETS_SLUG
  echo "export TF_VAR_INFISICAL_PROJECT_SLUG='$TF_VAR_INFISICAL_PROJECT_SLUG'" >> .env.local
  export TF_VAR_INFISICAL_ADMIN_USER=$INFISICAL_ADMIN_USER
  echo "export TF_VAR_INFISICAL_ADMIN_USER='$TF_VAR_INFISICAL_ADMIN_USER'" >> .env.local
  remote_url=$(git config --get remote.origin.url)
  remote_url=${remote_url%.git}
  path=${remote_url#*github.com[:/]}
  export TF_VAR_GITHUB_REPOSITORY=$path
  echo "export TF_VAR_GITHUB_REPOSITORY='$TF_VAR_GITHUB_REPOSITORY'" >> .env.local
  export TF_VAR_ORG_SHORTNAME=${path%%/*}
  echo "export TF_VAR_ORG_SHORTNAME='$TF_VAR_ORG_SHORTNAME'" >> .env.local
  repo_name=${path##*/}
  export TF_VAR_APP_SHORTNAME=${repo_name#compose-}
  echo "export TF_VAR_APP_SHORTNAME='$TF_VAR_APP_SHORTNAME'" >> .env.local
  echo "export APP_SHORTNAME='$TF_VAR_APP_SHORTNAME'" >> .env.local
  if command -v jq >/dev/null 2>&1 && [ -f .infisical.json ]; then
    export TF_VAR_ENV_SLUG=$(jq -r '.defaultEnvironment // empty' .infisical.json)
    echo "export TF_VAR_ENV_SLUG='$TF_VAR_ENV_SLUG'" >> .env.local
  fi

  make terraform/backend.tf > /dev/null 2>&1
  sed -i '/assume_role_with_web_identity/,/}/d' terraform/backend.tf
  cp terraform/providers.tf terraform/providers_override.tf
  sed -i 's/oidc/universal/g' terraform/providers_override.tf
  cp terraform/modules/infisical-project/providers.tf terraform/modules/infisical-project/providers_override.tf
  sed -i 's/oidc/universal/g' terraform/modules/infisical-project/providers_override.tf
fi

echo "Local development environment initialized."
echo "Run 'source .env.local' to set environment variables."
echo ""
echo "Don't forget to 'make lock' to remove local secrets when you are done for the day."