variable "auth0_apis" {
  description = "Map of Auth0 resource servers. Key is the API identifier (audience URL)."
  type = map(object({
    name           = string
    token_lifetime = optional(number, 86400)
    allow_offline  = optional(bool, false)
    scopes         = map(string)
  }))
  default = {}
}

variable "auth0_clients" {
  description = "Map of Auth0 applications. Key is a stable logical name."
  type = map(object({
    name                  = string
    app_type              = optional(string, "native")
    callbacks             = optional(list(string), [])
    logout_urls           = optional(list(string), [])
    grant_types           = optional(list(string), ["authorization_code", "refresh_token"])
    authentication_method = optional(string, "none")
    api_identifier        = optional(string, null)
    api_scopes            = optional(list(string), [])
  }))
  default = {}
}

variable "key_vault_id" {
  description = "Azure Key Vault resource ID to write Auth0 client credentials into."
  type        = string
}
