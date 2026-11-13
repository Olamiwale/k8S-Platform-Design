terraform {
  backend "s3" {
    bucket       = "k8s-platform-tfstate-234073095486"
    key          = "dev/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
