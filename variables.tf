variable "repositories" {
  description = "Map of repository configurations"
  type = map(object({
    description      = string
    branch_strategy  = string        # "gitflow" or "github-flow"
    visibility       = optional(string, "public")
    has_issues       = optional(bool, true)
    has_projects     = optional(bool, true)
    has_wiki         = optional(bool, true)
    has_downloads    = optional(bool, true)
  }))
  
  validation {
    condition = alltrue([
      for repo in var.repositories : 
      contains(["gitflow", "github-flow"], repo.branch_strategy)
    ])
    error_message = "branch_strategy must be either 'gitflow' or 'github-flow'."
  }
  
  default = {
    "github-test-1" = {
      description = "Test repository 1"
      branch_strategy = "gitflow"
    }
    "github-test-2" = {
      description = "Test repository 2"
      branch_strategy = "github-flow"
    }
  }
}

variable "branch_protection_settings" {
  description = "ブランチ保護設定"
  type = object({
    required_reviews           = optional(number, 1)
    dismiss_stale_reviews      = optional(bool, true)
    require_code_owner_reviews = optional(bool, false)
    enforce_admins            = optional(bool, false)
    required_status_checks    = optional(list(string), [])
  })
  default = {
    required_reviews           = 1
    dismiss_stale_reviews      = true
    require_code_owner_reviews = false
    enforce_admins            = false
    required_status_checks    = []
  }
}

# variable "github_token" {
#   description = "GitHub token for authentication"
#   type        = string
#   sensitive   = true
# }