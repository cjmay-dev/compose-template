# Common secrets needed for TF modules
data "infisical_projects" "common_secrets" {
  slug = var.INFISICAL_PROJECT_SLUG
}

data "infisical_secrets" "backup" {
  env_slug     = var.ENV_SLUG
  workspace_id = data.infisical_projects.common_secrets.id
  folder_path  = "/BACKUPS"
}

data "infisical_secrets" "cloudflare" {
  env_slug     = var.ENV_SLUG
  workspace_id = data.infisical_projects.common_secrets.id
  folder_path  = "/CLOUDFLARE"
}

data "infisical_secrets" "infisical" {
  env_slug     = var.ENV_SLUG
  workspace_id = data.infisical_projects.common_secrets.id
  folder_path  = "/INFISICAL"
}

data "infisical_secrets" "proxmox" {
  env_slug     = var.ENV_SLUG
  workspace_id = data.infisical_projects.common_secrets.id
  folder_path  = "/PROXMOX"
}

data "infisical_secrets" "tailscale" {
  env_slug     = var.ENV_SLUG
  workspace_id = data.infisical_projects.common_secrets.id
  folder_path  = "/TAILSCALE"
}

data "infisical_secrets" "tfstate" {
  env_slug     = var.ENV_SLUG
  workspace_id = data.infisical_projects.common_secrets.id
  folder_path  = "/TFSTATE"
}