# slat-iac

このディレクトリには、React Native / NestJS / Python サービスを AWS 上に構築するための Terraform 定義が含まれています。ここではローカル環境から手動で適用する手順をまとめます（GitHub Actions などの CI/CD 連携は後述の補足を参照）。

## 前提条件
- Terraform CLI 1.2 以上  
- AWS CLI など、AWS 認証情報を設定できる環境（`AWS_PROFILE` や `AWS_ACCESS_KEY_ID` など）
- 必要なコンテナイメージを Push 済みの ECR リポジトリ URI（`nestjs_image` / `python_image` 用）
- RDS で使用する DB ユーザー名・パスワード

## 1. 変数ファイルの作成
環境ごとの値は `terraform.tfvars` や `dev.tfvars` などのファイルで管理するのがおすすめです。例：

```hcl
# terraform.tfvars
project_name      = "slat"
environment       = "dev"
aws_region        = "ap-northeast-1"
db_username       = "slat_app"
db_password       = "change-me"
db_name           = "slat"
nestjs_image      = "123456789012.dkr.ecr.ap-northeast-1.amazonaws.com/nestjs:latest"
python_image      = "123456789012.dkr.ecr.ap-northeast-1.amazonaws.com/python-posture:latest"
allowed_api_cidrs = ["203.0.113.0/24"]
```

各種 CIDR や RDS のストレージサイズは `variables.tf` のデフォルト値を使うか、必要に応じて上書きしてください。

## 2. Terraform 実行
プロジェクトルート（`slat-iac` ディレクトリ）で以下を実行します。

```bash
terraform init
terraform plan  -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

初回適用は NAT Gateway や RDS なども作成するため数分かかります。`plan` の内容を必ずレビューしてから `apply` を実行してください。

## 3. 主要な出力
`terraform apply` 完了後に表示される出力例：

- `alb_dns_name` … NestJS API へアクセスする ALB の DNS 名  
- `rds_endpoint` / `rds_port` … アプリケーションから接続する PostgreSQL のエンドポイント  
- `vpc_id` … 作成された VPC の ID

## 4. クリーンアップ
検証環境を削除したい場合は以下を実行します（RDS や NAT Gateway の料金が継続しないよう注意）。

```bash
terraform destroy -var-file=terraform.tfvars
```

## 補足：CI/CD 連携について
現状はローカルで `terraform plan/apply` を実行する運用を想定しています。将来的に GitHub Actions や Terraform Cloud を利用して自動適用したい場合は、以下を追加検討してください。

- CI 上で AWS 認証情報を安全に扱う仕組み（OIDC、AWS IAM ロールなど）
- `terraform plan` を Pull Request で自動実行し、結果をコメントするワークフロー
- `terraform apply` を承認型にするか、タグ／ブランチでトリガーするかの運用設計

まずは手動適用で動作確認し、運用方針が固まった段階で CI/CD 導入を進めるのが一般的です。
