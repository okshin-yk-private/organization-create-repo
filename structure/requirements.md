# 目的
github actionsでgethub のリポジトリを作成するactionsを設定する。\

## 要件  
  1. リポジトリはpublicであること以外はデフォルトの設定\
  2. githubの認証はGithub apps。必要なid、などGithubのSecretに手動登録済み\
  3. stateファイルはaws s3に格納。awsへの認証はOIDCでIAM ROLEのarnはSecretに登録ずみ。
  4. リポジトリにはブランチを作成する。ブランチ構成は2通り。1つはproduction-staging-deverop構成。もう一つはgithub-flow構成。
    4-1. production-staging-deverop構成には以下のブランチを作成する。
      - production:本番用
      - staging:ステージング用。
      - develop:開発用。
    4-2. github-flow構成には以下のブランチを作成する。
      - main：本番用
  5. ブランチ保護ルールを作成する。構成は以下。
    5-1. production-staging-deverop構成
      5-1-1. Productionブランチへのルール
        - 直接編集の禁止
        - stagingからのpull requestを経由するmargeのみ許可 
      5-1-2. Stagingブランチへのルール
        - 直接編集の禁止
        - developからのpull requestを経由するmargeのみ許可
      5-1-3. Developブランチへのルール
        - 直接編集の禁止
        - featureが名称に含まれるブランチからのpull requestを経由するmargeのみ許可
    5-2. github-flow構成
         - mainブランチへの直接編集の禁止
         - featureが名称に含まれるブランチからのpull requestを経由するmargeのみ許可
  6. terraformのvaliableの指定によって作成するリポジトリのブランチ構成production-stageng-develop構成かgithub-flow構成かを指定できる。 