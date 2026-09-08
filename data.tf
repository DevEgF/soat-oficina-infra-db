data "terraform_remote_state" "k8s" {
  backend = "s3"

  config = {
    bucket       = var.state_bucket
    key          = "infra-k8s/terraform.tfstate"
    region       = var.aws_region
    use_lockfile = true
  }
}
