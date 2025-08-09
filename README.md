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
   - **update_existing**: `false`（デフォルト）
   - **debug_mode**: デバッグ出力が必要な場合は `true`

### 既存リポジトリの更新

既存リポジトリのブランチ戦略や保護ルールを更新する場合：

1. **update_existing** を `true` に設定
2. その他のパラメータを必要に応じて設定
3. ワークフローを実行

## セキュリティ機能

### 1. 既存リポジトリチェック
- 実行前に既存リポジトリの存在を確認
- デフォルトでは既存リポジトリがある場合エラー

### 2. 削除操作の検出と防止
- Terraform planで削除操作を検出
- 新規作成モード: すべての削除操作を禁止
- 更新モード: リポジトリ本体の削除のみ禁止

### 3. 動的バックエンド
- 各リポジトリが独自の状態ファイルを持つ
- `s3://bucket/github/repos/{repository_name}/terraform.tfstate`
- リポジトリ間の干渉を防止

## ブランチ戦略

### GitFlow
作成されるブランチ:
- `main` (保護)
- `develop` (保護)
- `staging` (保護)

### GitHub Flow
作成されるブランチ:
- `main` (保護のみ)

## トラブルシューティング

### 既存リポジトリエラー
```
❌ エラー: 既存リポジトリが存在します
```
**対処法:**
1. 別のリポジトリ名を使用
2. `update_existing` を `true` に設定して更新モードで実行
3. 既存リポジトリを手動で削除してから再実行

### 削除操作検出エラー
```
❌ エラー: 削除操作が検出されました
```
**対処法:**
- Terraform設定を確認
- 更新モードでの実行を検討

## 設定ファイル

### 必要なシークレット

- `ROLE_ARN`: TerraformのAWS認証用IAMロール
- `GH_APP_APP_ID`: GitHub App ID
- `GH_APP_PRIVATE_KEY`: GitHub App プライベートキー

### Terraform設定

- `main.tf`: リポジトリとブランチのリソース定義
- `variables.tf`: 入力変数の定義
- `providers.tf`: プロバイダー設定
- `backend.tf`: 動的生成（.gitignoreに含まれる）

## 注意事項

- `backend.tf`はGitHub Actionsによって動的に生成されるため、リポジトリにコミットしないでください
- 各リポジトリの状態ファイルはS3の個別パスに保存されます
- 同名リポジトリの再作成には手動での削除が必要です