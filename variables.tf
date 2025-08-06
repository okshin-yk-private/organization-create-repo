variable "repositories" {
  description = "Map of repository configurations"
  type = map(object({
    description    = string
    visibility     = optional(string, "private")
    has_issues     = optional(bool, true)
    has_projects   = optional(bool, true)
    has_wiki       = optional(bool, true)
    has_downloads  = optional(bool, true)
  }))
  default = {
    "github-test-1" = {
      description = "Test repository 1"
    }
    "github-test-2" = {
      description = "Test repository 2"
    }
  }
}

# variable "github_token" {
#   description = "GitHub token for authentication"
#   type        = string
#   sensitive   = true
# }