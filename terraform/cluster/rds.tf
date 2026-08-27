module "rds" {
  source           = "../modules/rds"
  tag_env          = var.tag_env
  vpc_id           = module.vpc.vpc_id
  database_subnets = module.vpc.database_subnets
  security_groups  = [module.eks.node_security_group_id, module.bastion.security_group_id]
}
