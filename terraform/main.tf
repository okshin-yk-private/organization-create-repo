locals {
  # ブランチ戦略別のブランチ設定
  branch_config = {
    strategy = var.repository.branch_strategy
    branches = var.repository.branch_strategy == "gitflow" ? {
      production = { source = "main", protected = true, from_branches = ["staging"] }
      staging    = { source = "main", protected = true, from_branches = ["develop"] }
      develop    = { source = "main", protected = true, from_branches = ["feature/*"] }
      } : {
      main = { source = null, protected = true, from_branches = ["feature/*"] }
    }
  }

  # ブランチリスト
  branches = [
    for branch_name, branch_config in local.branch_config.branches : {
      branch_name   = branch_name
      source_branch = branch_config.source
      is_protected  = branch_config.protected
      from_branches = branch_config.from_branches
    }
  ]

  # ブランチ保護ルール設定
  protection_rules = {
    for branch in local.branches : branch.branch_name => {
      branch_name                     = branch.branch_name
      required_approving_review_count = branch.branch_name == "develop" ? 0 : var.branch_protection_settings.required_reviews
      dismiss_stale_reviews           = var.branch_protection_settings.dismiss_stale_reviews
      require_code_owner_reviews      = var.branch_protection_settings.require_code_owner_reviews
      enforce_admins                  = var.branch_protection_settings.enforce_admins
      required_status_checks          = var.branch_protection_settings.required_status_checks
      from_branches                   = branch.from_branches
    } if branch.is_protected
  }
}

resource "github_repository" "repo" {
  name        = var.repository.name
  description = var.repository.description

  visibility = var.repository.visibility

  has_issues    = var.repository.has_issues
  has_projects  = var.repository.has_projects
  has_wiki      = var.repository.has_wiki
  has_downloads = var.repository.has_downloads

  auto_init          = true
  gitignore_template = "VisualStudio"

  allow_merge_commit     = true
  allow_squash_merge     = true
  allow_rebase_merge     = true
  allow_auto_merge       = false
  delete_branch_on_merge = true

  vulnerability_alerts = true
}

# カスタムREADME.mdファイルの作成（readme_contentが指定された場合のみ）
resource "github_repository_file" "readme" {
  count = var.readme_content != null ? 1 : 0

  repository          = github_repository.repo.name
  branch              = "main"
  file                = "README.md"
  content             = var.readme_content
  commit_message      = "Add custom README.md"
  commit_author       = "Terraform"
  commit_email        = "terraform@example.com"
  overwrite_on_create = true

  depends_on = [github_repository.repo]
}

# ブランチ作成（mainブランチ以外）
resource "github_branch" "branches" {
  for_each = {
    for branch in local.branches : branch.branch_name => branch
    if branch.branch_name != "main" && branch.source_branch != null
  }

  repository    = github_repository.repo.name
  branch        = each.value.branch_name
  source_branch = each.value.source_branch

  depends_on = [github_repository.repo]
}

# 動的ブランチ保護ルール
resource "github_branch_protection" "protection" {
  for_each = local.protection_rules

  repository_id = github_repository.repo.node_id
  pattern       = each.value.branch_name

  # プルリクエストレビュー要求
  required_pull_request_reviews {
    required_approving_review_count = each.value.required_approving_review_count
    dismiss_stale_reviews           = each.value.dismiss_stale_reviews
    require_code_owner_reviews      = each.value.require_code_owner_reviews
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
    github_repository.repo,
    github_branch.branches
  ]
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

output "repository_branches" {
  description = "ブランチ戦略とブランチ情報"
  value = {
    strategy = local.branch_config.strategy
    branches = keys(local.branch_config.branches)
    protected_branches = [
      for branch_name, branch_config in local.branch_config.branches : branch_name
      if branch_config.protected
    ]
  }
}

output "created_branches" {
  description = "実際に作成されたブランチの詳細情報"
  value = {
    for k, v in github_branch.branches : k => {
      repository    = v.repository
      branch_name   = v.branch
      source_branch = v.source_branch
    }
  }
}

output "branch_protection_summary" {
  description = "ブランチ保護ルールのサマリー"
  value = {
    for k, v in local.protection_rules : k => {
      branch                  = v.branch_name
      required_reviews        = v.required_approving_review_count
      dismiss_stale_reviews   = v.dismiss_stale_reviews
      enforce_admins          = v.enforce_admins
      allowed_source_branches = v.from_branches
    }
  }
}