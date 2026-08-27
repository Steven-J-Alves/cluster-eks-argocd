module "bastion" {
  source         = "../modules/bastion"
  tag_env        = var.tag_env
  vpc_id         = module.vpc.vpc_id
  public_subnets = module.vpc.public_subnets
  public_key     = var.id_rsa
}
