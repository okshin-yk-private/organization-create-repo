resource "github_repository" "repo" {
  name        = var.repository_name
  description = var.repository_description
  
  visibility = "private"
  
  has_issues      = true
  has_projects    = true
  has_wiki        = true
  has_downloads   = true
  
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

resource "github_repository_ruleset" "main" {
  repository = github_repository.repo.name
  name       = "main-branch-protection"
  target     = "branch"
  enforcement = "active"
  
  conditions {
    ref_name {
      include = ["~DEFAULT_BRANCH"]
      exclude = []
    }
  }
  
  rules {
    # プルリクエストを要求
    pull_request {
      required_approving_review_count = 0
      dismiss_stale_reviews_on_push = false
      require_code_owner_review = false
      require_last_push_approval = false
    }
    
    # 直接プッシュを制限
    creation = false
    deletion = false
    non_fast_forward = false
    required_linear_history = false
    required_signatures = false
    update = false
  }
}

output "repository_url" {
  description = "The URL of the created repository"
  value       = github_repository.repo.html_url
}

output "repository_name" {
  description = "The name of the created repository"
  value       = github_repository.repo.name
}

output "repository_full_name" {
  description = "The full name of the repository (owner/name)"
  value       = github_repository.repo.full_name
}