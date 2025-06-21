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

variable "github_app_id" {
  description = "GitHub App ID for authentication"
  type        = string
  sensitive   = true
}

variable "github_app_installation_id" {
  description = "GitHub App Installation ID"
  type        = string
  sensitive   = true
}

variable "github_app_pem_file" {
  description = "GitHub App Private Key (PEM content)"
  type        = string
  sensitive   = true
}