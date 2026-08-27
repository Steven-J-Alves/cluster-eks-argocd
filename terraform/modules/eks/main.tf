module "this" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.31"

  cluster_name                    = var.cluster_name
  cluster_version                 = var.cluster_version
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  enable_cluster_creator_admin_permissions = true

  cluster_addons = {
    coredns    = { most_recent = true }
    kube-proxy = { most_recent = true }
    vpc-cni    = { most_recent = true }
  }

  node_security_group_additional_rules = {
    ingress_source_security_group_id = {
      description              = "Ingress from another computed security group"
      protocol                 = "tcp"
      from_port                = 80
      to_port                  = 80
      type                     = "ingress"
      source_security_group_id = module.this.node_security_group_id
    }
  }

  eks_managed_node_groups = {
    internal-service = {
      min_size                     = var.node_min_size
      max_size                     = var.node_max_size
      desired_size                 = var.node_desired_size
      disk_size                    = var.node_disk_size
      instance_types               = var.node_instance_types
      capacity_type                = var.node_capacity_type
      subnet_ids                   = var.subnet_ids
      # For simplicity common Admin rights — tighten for production
      iam_role_additional_policies = { AdministratorAccess = "arn:aws:iam::aws:policy/AdministratorAccess" }
    }
  }
}
