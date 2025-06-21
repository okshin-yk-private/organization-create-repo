terraform {
  backend "s3" {
    bucket = "yk-private-terraform"
    key    = "github/organization/github-org-test/terraform.tfstate"
    region = "ap-northeast-1"
  }
}