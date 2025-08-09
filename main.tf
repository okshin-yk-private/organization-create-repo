locals {
  # ブランチ戦略別のブランチ設定
  branch_configs = {
    for repo_name, repo_config in var.repositories : repo_name => {
      strategy = repo_config.branch_strategy
      branches = repo_config.branch_strategy == "gitflow" ? {
        production = { source = "main", protected = true, from_branches = ["staging"] }
        staging    = { source = "main", protected = true, from_branches = ["develop"] }
        develop    = { source = "main", protected = true, from_branches = ["feature/*"] }
      } : {
        main = { source = null, protected = true, from_branches = ["feature/*"] }
      }
    }
  }
  
  # フラット化されたブランチリスト（for_each用）
  branches = flatten([
    for repo_name, config in local.branch_configs : [
      for branch_name, branch_config in config.branches : {
        repo_name     = repo_name
        branch_name   = branch_name
        source_branch = branch_config.source
        is_protected  = branch_config.protected
        from_branches = branch_config.from_branches
        key           = "${repo_name}:${branch_name}"
      }
    ]
  ])
  
  # ブランチ保護ルール設定
  protection_rules = {
    for branch in local.branches : branch.key => {
      repo_name                        = branch.repo_name
      branch_name                      = branch.branch_name
      required_approving_review_count  = branch.branch_name == "develop" ? 0 : var.branch_protection_settings.required_reviews
      dismiss_stale_reviews            = var.branch_protection_settings.dismiss_stale_reviews
      require_code_owner_reviews       = var.branch_protection_settings.require_code_owner_reviews
      enforce_admins                   = var.branch_protection_settings.enforce_admins
      required_status_checks           = var.branch_protection_settings.required_status_checks
      from_branches                    = branch.from_branches
    } if branch.is_protected
  }
}

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

# ブランチ作成（mainブランチ以外）
resource "github_branch" "branches" {
  for_each = {
    for branch in local.branches : branch.key => branch
    if branch.branch_name != "main" && branch.source_branch != null
  }
  
  repository    = github_repository.repos[each.value.repo_name].name
  branch        = each.value.branch_name
  source_branch = each.value.source_branch
  
  depends_on = [github_repository.repos]
}

# 動的ブランチ保護ルール
resource "github_branch_protection" "protection" {
  for_each = local.protection_rules
  
  repository_id = github_repository.repos[each.value.repo_name].node_id
  pattern       = each.value.branch_name
  
  # プルリクエストレビュー要求
  required_pull_request_reviews {
    required_approving_review_count = each.value.required_approving_review_count
    dismiss_stale_reviews          = each.value.dismiss_stale_reviews
    require_code_owner_reviews     = each.value.require_code_owner_reviews
  }
  
  # ステータスチェック要求（設定されている場合）
  dynamic "required_status_checks" {
    for_each = length(each.value.required_status_checks) > 0 ? [1] : []
    content {
      strict   = false
      contexts = each.value.required_status_checks
    }
  }
  
  # 管理者への強制適用
  enforce_admins = each.value.enforce_admins
  
  # プッシュの制限（直接プッシュを防ぐ）
  allows_deletions    = false
  allows_force_pushes = false
  
  depends_on = [
    github_repository.repos,
    github_branch.branches
  ]
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

output "repository_branches" {
  description = "各リポジトリのブランチ戦略とブランチ情報"
  value = {
    for repo_name, config in local.branch_configs : repo_name => {
      strategy = config.strategy
      branches = keys(config.branches)
      protected_branches = [
        for branch_name, branch_config in config.branches : branch_name
        if branch_config.protected
      ]
    }
  }
}

output "created_branches" {
  description = "実際に作成されたブランチの詳細情報"
  value = {
    for k, v in github_branch.branches : k => {
      repository = v.repository
      branch_name = v.branch
      source_branch = v.source_branch
    }
  }
}

output "branch_protection_summary" {
  description = "ブランチ保護ルールのサマリー"
  value = {
    for k, v in local.protection_rules : k => {
      branch = v.branch_name
      required_reviews = v.required_approving_review_count
      dismiss_stale_reviews = v.dismiss_stale_reviews
      enforce_admins = v.enforce_admins
      allowed_source_branches = v.from_branches
    }
  }
}