module "vpc" {
  source  = "../modules/vpc"
  tag_env = var.tag_env
  cidr    = var.vpc_cidr
}
