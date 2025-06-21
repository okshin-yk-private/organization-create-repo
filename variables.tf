variable "repository_name" {
  description = "Name of the GitHub repository to create"
  type        = string
  default     = "github-test"
}

variable "repository_description" {
  description = "Description of the GitHub repository"
  type        = string
  default     = "test"
}

variable "github_token" {
  description = "GitHub token for authentication"
  type        = string
  sensitive   = true
}

variable "github_owner" {
  description = "GitHub owner (organization or user)"
  type        = string
}