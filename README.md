# GitHub Organization Repository Creator

GitHub ActionsとTerraformを使用して、組織内にリポジトリを自動作成するツールです。

## 機能

- GitHubリポジトリの自動作成
- ブランチ戦略の選択（GitFlow / GitHub Flow）
- ブランチ保護ルールの自動設定
- **動的バックエンド管理**: 各リポジトリが独立した状態ファイルを持つ
- **既存リポジトリ保護**: 誤って既存リポジトリを削除しないための安全機構

## 前提条件

- AWS S3バケット（Terraform状態管理用）
- GitHub App（リポジトリ作成権限付き）
- GitHub Actions用のAWS IAMロール

## 使用方法

### 新規リポジトリの作成

1. Actions タブに移動
2. "Create GitHub Repository" ワークフローを選択
3. "Run workflow" をクリック
4. 以下のパラメータを入力：
   - **repository_name**: 作成するリポジトリ名
   - **branch_strategy**: `gitflow` または `github-flow`
   - **update_existing**: チェックしない（デフォルト）
   - **debug_mode**: デバッグ出力が必要な場合はチェック

### 既存リポジトリの更新

既存リポジトリのブランチ戦略や保護ルールを更新する場合：

1. **update_existing** にチェックを入れる
2. その他のパラメータを必要に応じて設定
3. ワークフローを実行

## セキュリティ機能

### 1. 既存リポジトリチェック
- 実行前にGitHub APIで既存リポジトリの存在を確認
- デフォルトでは既存リポジトリがある場合はエラーで停止

### 2. 動的バックエンド管理
- 各リポジトリが独自の状態ファイルを持つ
- `s3://yk-private-terraform/github/repos/{repository_name}/terraform.tfstate`
- リポジトリ間の状態ファイル競合を防止

### 3. 明示的な更新許可
- デフォルトは新規作成モードで安全
- 既存リポジトリの更新には明示的なチェックが必要

## ブランチ戦略

### GitFlow
作成されるブランチ:
- `main` (デフォルトブランチ)
- `production` (mainから作成、保護)
- `staging` (mainから作成、保護)
- `develop` (mainから作成、保護)

### GitHub Flow
作成されるブランチ:
- `main` (デフォルトブランチ、保護のみ)

## トラブルシューティング

### 既存リポジトリエラー
```
❌ 既存リポジトリが存在するため処理を中止します
update_existing パラメータを true に設定すると更新モードで実行できます
```
**対処法:**
1. 別のリポジトリ名を使用
2. `update_existing` にチェックを入れて更新モードで実行
3. 既存リポジトリを手動で削除してから再実行

### Terraform関連エラー
```
❌ Terraform planが失敗しました
```
**対処法:**
- AWS認証情報を確認
- GitHub App権限を確認
- S3バケットへのアクセス権限を確認

## 設定ファイル

### 必要なシークレット

GitHub Actionsのリポジトリシークレットに以下を設定：

- `ROLE_ARN`: TerraformのAWS認証用IAMロール
- `GH_APP_APP_ID`: GitHub App ID
- `GH_APP_PRIVATE_KEY`: GitHub App プライベートキー

### プロジェクト構成

```
.
├── .github/workflows/
│   └── create-repository.yml    # GitHub Actions ワークフロー
├── main.tf                      # リポジトリとブランチのリソース定義
├── variables.tf                 # 入力変数の定義
├── providers.tf                 # プロバイダー設定
├── terraform.tfvars.example     # 設定例
├── structure/                   # プロジェクト設計書類
└── README.md
```

### 動的生成ファイル

以下のファイルはGitHub Actions実行時に動的生成されます（.gitignoreに含まれる）：

- `backend.tf`: リポジトリ名に基づいた動的バックエンド設定
- `terraform.tfvars`: 実行時パラメータ

## 注意事項

- `backend.tf`と`terraform.tfvars`はGitHub Actionsによって動的に生成されるため、リポジトリにコミットされません
- 各リポジトリの状態ファイルはS3の個別パス（`github/repos/{repository_name}/`）に保存されます
- 同名リポジトリの再作成には、既存リポジトリの手動削除または`update_existing`チェックが必要です
- ブランチ戦略を変更すると既存ブランチが削除・再作成される場合があります（更新モードのみ）

## ライセンス

このプロジェクトで作成されるリポジトリは、デフォルトでMITライセンスが適用されます。