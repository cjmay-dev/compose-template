module "b2_bucket" {
  source        = "./modules/b2-bucket"
  APP_SHORTNAME = var.APP_SHORTNAME
  ORG_SHORTNAME = var.ORG_SHORTNAME
  ENV_SLUG      = var.ENV_SLUG
  B2_KEY_ID     = data.infisical_secrets.backup.secrets["BACKBLAZE_B2_KEY_ID"].value
  B2_KEY_SECRET = data.infisical_secrets.backup.secrets["BACKBLAZE_B2_KEY_SECRET"].value
}

module "cloudflare_tunnel" {
  source                = "./modules/cloudflare-tunnel"
  APP_SHORTNAME         = var.APP_SHORTNAME
  ENV_SLUG              = var.ENV_SLUG
  CLOUDFLARE_DOMAIN     = data.infisical_secrets.cloudflare.secrets["CLOUDFLARE_DOMAIN"].value
  CLOUDFLARE_ACCOUNT_ID = data.infisical_secrets.cloudflare.secrets["CLOUDFLARE_ACCOUNT_ID"].value
  CLOUDFLARE_ZONE_ID    = data.infisical_secrets.cloudflare.secrets["CLOUDFLARE_ZONE_ID"].value
  CLOUDFLARE_API_TOKEN  = data.infisical_secrets.cloudflare.secrets["CLOUDFLARE_API_TOKEN"].value
}

module "infisical_project" {
  source        = "./modules/infisical-project"
  APP_SECRETS   = {
    "APP_SHORTNAME" = var.APP_SHORTNAME
    "ORG_SHORTNAME" = var.ORG_SHORTNAME
    "LOCAL_DOMAIN" = data.infisical_secrets.proxmox.secrets["LOCAL_DOMAIN"].value
    "GITHUB_REPOSITORY" = var.GITHUB_REPOSITORY
    "ANSIBLE_BECOME_PASSWORD" = module.proxmox_vm.ansible_password
    "ANSIBLE_SSH_PRIVATE_KEY" = module.proxmox_vm.ansible_ssh_private_key
    "CLOUDFLARE_DOMAIN" = data.infisical_secrets.cloudflare.secrets["CLOUDFLARE_DOMAIN"].value
    "CLOUDFLARE_TUNNEL_TOKEN" = module.cloudflare_tunnel.tunnel_token
    "B2_BUCKET_KEY_ID" = module.b2_bucket.bucket_key_id
    "B2_BUCKET_KEY_SECRET" = module.b2_bucket.bucket_key_secret
    "RESTIC_REPOSITORY" = module.b2_bucket.bucket_s3_uri
    "RESTIC_BACKUP_PASSWORD" = data.infisical_secrets.backup.secrets["RESTIC_BACKUP_PASSWORD"].value
    "STACKBACK_DISCORD_WEBHOOK" = data.infisical_secrets.backup.secrets["STACKBACK_DISCORD_WEBHOOK"].value
  }
  APP_SHORTNAME = var.APP_SHORTNAME
  ORG_SHORTNAME = var.ORG_SHORTNAME
  DOMAIN        = data.infisical_secrets.cloudflare.secrets["CLOUDFLARE_DOMAIN"].value
  ENV_SLUG      = var.ENV_SLUG
  GITHUB_REPOSITORY   = var.GITHUB_REPOSITORY
  INFISICAL_ADMIN_USER = data.infisical_secrets.infisical.secrets["INFISICAL_ADMIN_USER"].value
}

module "proxmox_vm" {
  source        = "./modules/proxmox-vm"
  PVE_HOST      = data.infisical_secrets.proxmox.secrets["PVE_HOST"].value
  NODE_NAME     = "pve"
  APP_SHORTNAME = var.APP_SHORTNAME
  LOCAL_DOMAIN  = data.infisical_secrets.proxmox.secrets["LOCAL_DOMAIN"].value
  ADMIN_USERNAME = data.infisical_secrets.proxmox.secrets["ADMIN_USERNAME"].value
  ADMIN_SSH_PUBLIC_KEY = data.infisical_secrets.proxmox.secrets["ADMIN_SSH_PUBLIC_KEY"].value
  CPU_CORES    = 2
  MEMORY      = 4096
  DISK_SIZE   = 64
  DATASTORE_ID  = data.infisical_secrets.proxmox.secrets["DATASTORE_ID"].value
  NETWORK_BRIDGE = "vmbr1"
}