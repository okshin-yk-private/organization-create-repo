variable "repository" {
  description = "Repository configuration"
  type = object({
    name            = string
    description     = string
    branch_strategy = string                     # "gitflow" or "github-flow"
    visibility      = optional(string, "public") # "public" or "private" enterpriseでは"private"推奨
    has_issues      = optional(bool, true)
    has_projects    = optional(bool, true)
    has_wiki        = optional(bool, true)
    has_downloads   = optional(bool, true)
  })

  validation {
    condition = contains(["gitflow", "github-flow"], var.repository.branch_strategy)
    error_message = "branch_strategy must be either 'gitflow' or 'github-flow'."
  }
}

variable "branch_protection_settings" {
  description = "ブランチ保護設定"
  type = object({
    required_reviews           = optional(number, 1)
    dismiss_stale_reviews      = optional(bool, true)
    require_code_owner_reviews = optional(bool, false)
    enforce_admins             = optional(bool, false)
    required_status_checks     = optional(list(string), [])
  })
  default = {
    required_reviews           = 1
    dismiss_stale_reviews      = true
    require_code_owner_reviews = false
    enforce_admins             = false
    required_status_checks     = []
  }
}