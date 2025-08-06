resource "github_repository" "repos" {
  for_each = var.repositories
  
  name        = each.key
  description = each.value.description
  
  visibility = each.value.visibility
  
  has_issues      = each.value.has_issues
  has_projects    = each.value.has_projects
  has_wiki        = each.value.has_wiki
  has_downloads   = each.value.has_downloads
  
  auto_init          = true
  gitignore_template = "VisualStudio"
  license_template   = "mit"
  
  allow_merge_commit     = true
  allow_squash_merge     = true
  allow_rebase_merge     = true
  allow_auto_merge       = false
  delete_branch_on_merge = true
  
  vulnerability_alerts = true
}

resource "github_branch_protection" "main" {
  for_each = github_repository.repos
  
  repository_id = each.value.node_id
  pattern       = "main"
  
  # プルリクエストを要求
  required_pull_request_reviews {
    required_approving_review_count = 0
    dismiss_stale_reviews = false
    require_code_owner_reviews = false
  }
}

output "repository_urls" {
  description = "The URLs of the created repositories"
  value       = { for k, v in github_repository.repos : k => v.html_url }
}

output "repository_names" {
  description = "The names of the created repositories"
  value       = { for k, v in github_repository.repos : k => v.name }
}

output "repository_full_names" {
  description = "The full names of the repositories (owner/name)"
  value       = { for k, v in github_repository.repos : k => v.full_name }
}