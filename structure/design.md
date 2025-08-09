# 設計方針

## 1. プロジェクト概要

GitHub ActionsとTerraformを使用してGitHubリポジトリを動的に作成し、ブランチ構成とブランチ保護ルールを自動設定するシステムの設計。

### 1.1 目標
- 変数による柔軟なブランチ構成の選択（production-staging-develop構成 vs github-flow構成）
- 各ブランチ構成に適した保護ルールの自動設定
- 安全で保守しやすいTerraform構成の実現

## 2. システムアーキテクチャ

### 2.1 全体構成
```
GitHub Actions Workflow
├── AWS OIDC認証
├── GitHub App認証
├── Terraformによるリソース管理
│   ├── リポジトリ作成
│   ├── ブランチ作成（条件分岐）
│   └── ブランチ保護ルール設定（条件分岐）
└── AWS S3ステートファイル管理
```

### 2.2 Terraform構造設計
```
プロジェクトルート/
├── main.tf           # メインリソース定義
├── variables.tf      # 変数定義
├── providers.tf      # プロバイダ設定
├── backend.tf        # S3バックエンド設定
├── outputs.tf        # アウトプット定義
└── modules/          # モジュール（必要に応じて）
    ├── repository/   # リポジトリ作成モジュール
    ├── branches/     # ブランチ管理モジュール
    └── protection/   # ブランチ保護モジュール
```

## 3. ブランチ戦略設計

### 3.1 Production-Staging-Develop構成
**ブランチ構成:**
- `production`: 本番環境用メインブランチ
- `staging`: ステージング環境用ブランチ
- `develop`: 開発統合ブランチ

**ブランチ保護ルール:**
- **productionブランチ**
  - 直接プッシュ禁止
  - stagingブランチからのPRのみ許可
  - レビュー必須（1名以上）
  - ステータスチェック必須
  
- **stagingブランチ**
  - 直接プッシュ禁止
  - developブランチからのPRのみ許可
  - レビュー必須（1名以上）
  
- **developブランチ**
  - 直接プッシュ禁止
  - feature/*ブランチからのPRのみ許可

### 3.2 GitHub Flow構成
**ブランチ構成:**
- `main`: 本番環境用メインブランチ

**ブランチ保護ルール:**
- **mainブランチ**
  - 直接プッシュ禁止
  - feature/*ブランチからのPRのみ許可
  - レビュー必須（1名以上）
  - ステータスチェック必須

## 4. 変数設計

### 4.1 主要変数
```hcl
variable "repositories" {
  description = "リポジトリ設定のマップ"
  type = map(object({
    description      = string
    branch_strategy  = string        # "gitflow" or "github-flow"
    visibility       = optional(string, "public")
    # その他のリポジトリ設定
  }))
}

variable "branch_protection_settings" {
  description = "ブランチ保護設定"
  type = object({
    required_reviews = optional(number, 1)
    dismiss_stale_reviews = optional(bool, true)
    require_code_owner_reviews = optional(bool, false)
    enforce_admins = optional(bool, false)
  })
  default = {}
}
```

### 4.2 条件分岐ロジック
- `branch_strategy`変数による動的リソース作成
- `count`または`for_each`を使用した条件付きリソース作成
- `locals`ブロックでの設定値計算

## 5. 実装方針

### 5.1 コード品質
- DRY原則の適用（重複排除）
- 明確な命名規則
- 適切なコメント
- バリデーション機能

### 5.2 セキュリティ
- GitHub App認証の使用
- AWS OIDC認証によるキーレス認証
- 最小権限の原則
- シークレット管理の適切な分離

### 5.3 保守性
- モジュール化による機能分離
- 設定の外部化
- エラーハンドリング
- ログ出力の充実

## 6. GitHub Actions統合

### 6.1 ワークフロー改善点
- 入力パラメータによるブランチ戦略選択
- 実行前のplanレビュー機能
- 失敗時のロールバック機能
- 詳細なログ出力

### 6.2 セキュリティ強化
- GitHub App権限の最小化
- AWS IAMロールの適切なスコープ
- ステートファイルの暗号化
- シークレットの適切な管理

## 7. テスト戦略

### 7.1 ローカルテスト
- `terraform plan`での構文チェック
- `terraform validate`での検証
- ローカル環境でのdry-run

### 7.2 統合テスト
- テスト用リポジトリでの実行検証
- 各ブランチ構成での動作確認
- ブランチ保護ルールの機能検証

## 8. デプロイメント計画

### 8.1 段階的デプロイ
1. 基本機能の実装とテスト
2. ブランチ作成機能の追加
3. ブランチ保護ルールの実装
4. エラーハンドリングの強化

### 8.2 運用考慮事項
- ステートファイルのバックアップ
- 設定変更時の影響範囲確認
- ドキュメントの維持更新
- モニタリングとアラート

## 9. 拡張性

### 9.1 今後の機能拡張
- 複数組織への対応
- カスタムブランチ戦略の追加
- チーム権限管理の自動化
- CI/CDパイプライン設定の自動化

### 9.2 アーキテクチャの柔軟性
- プラグイン機能による拡張
- 設定ファイルによるカスタマイズ
- APIによる外部システム連携
- Webhookによるイベント連携