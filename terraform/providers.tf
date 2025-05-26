terraform {
  required_providers {
    infisical = {
      source  = "infisical/infisical"
      version = "0.15.10"
    }
  }
}

provider "infisical" {
  # requires environment variable "INFISICAL_HOST"
  auth = {
    oidc = {
      # requires environment variable "INFISICAL_MACHINE_IDENTITY_ID"
      # requires environment variable "INFISICAL_AUTH_JWT"
    }
    # universal = {
    #   # requires environment variable "INFISICAL_UNIVERSAL_AUTH_CLIENT_ID"
    #   # requires environment variable "INFISICAL_UNIVERSAL_AUTH_CLIENT_SECRET"
    # }
  }
}