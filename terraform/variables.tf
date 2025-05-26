variable APP_SHORTNAME {
    description = "Subdomain where the app is hosted"
    type        = string
    default     = "appshortname"
}

variable "ORG_SHORTNAME" {
    description = "Single-word name of organization"
    type        = string
    default     = "orgshortname"
}

variable "ENV_SLUG" {
    description = "Environment slug"
    type        = string
    default     = "prod"
}

variable "INFISICAL_PROJECT_SLUG" {
    description = "Project slug for common/shared secrets"
    type        = string
}

variable "INFISICAL_ADMIN_USER" {
    description = "Admin user for Infisical"
    type        = string
}