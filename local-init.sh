#!/bin/bash


if ! terraform --version > /dev/null 2>&1; then
  echo "Terraform CLI is not installed. Please install it first."
  exit 1
fi

if ! infisical --version > /dev/null 2>&1; then
  echo "Infisical CLI is not installed. Please install it first."
  exit 1
fi

if ! infisical export -t nonexistent >/dev/null 2>&1; then
  infisical login
fi

if [ -f .infisical.json ]; then
  echo "Infisical is already initialized."
else
  echo "Initializing Infisical..."
  infisical init
  # assume the local environment is "dev"
  jq '.defaultEnvironment="dev"' .infisical.json > /tmp/infisical.$$.json \
    && mv /tmp/infisical.$$.json .infisical.json
  echo "Infisical initialized with default environment 'dev'."
  echo "Manually edit .infisical.json to change the default environment."
  echo
  echo "Re-run this script once the correct environment is set."
  exit 0
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

if ! curl -k --silent --head $PROXMOX_VE_ENDPOINT > /dev/null; then
  echo "Error: Cannot reach PVE at $PROXMOX_VE_ENDPOINT"
  echo "Please connect to the Tailnet and try again."
  exit 1
fi

export TF_VAR_INFISICAL_PROJECT_SLUG=$INFISICAL_COMMON_SECRETS_SLUG
export TF_VAR_INFISICAL_ADMIN_USER=$INFISICAL_ADMIN_USER
remote_url=$(git config --get remote.origin.url)
remote_url=${remote_url%.git}
path=${remote_url#*github.com[:/]}
export TF_VAR_ORG_SHORTNAME=${path%%/*}
repo_name=${path##*/}
export TF_VAR_APP_SHORTNAME=${repo_name#compose-}
if command -v jq >/dev/null 2>&1 && [ -f .infisical.json ]; then
  export TF_VAR_ENV_SLUG=$(jq -r '.defaultEnvironment // empty' .infisical.json)
fi

make terraform/backend.tf
sed -i '/assume_role_with_web_identity/,/}/d' terraform/backend.tf
