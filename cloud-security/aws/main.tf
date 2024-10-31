provider "aws" {
  region = var.region
  profile = var.aws_profile
}

module "vpcflow" {
  source                = "./modules/vpcflow"
  bucket_name           = var.bucket_name
  vpc_id                = var.vpc_id
  log_format            = var.log_format
  enable_delete_permission = var.enable_delete_permission
  environment           = var.environment
}