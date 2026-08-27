resource "random_password" "db_name" {
  length  = 7
  special = false
  numeric = false
}

resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "!#"
}

resource "random_password" "admin_username" {
  length  = 7
  special = false
  numeric = false
}

module "this" {
  source  = "cloudposse/rds-cluster/aws"
  version = "~> 1.15"

  name                 = "rds-${var.tag_env}"
  engine               = "aurora-mysql"
  engine_mode          = "provisioned"
  cluster_family       = "aurora-mysql8.0"
  instance_type        = "db.t3.medium"
  cluster_size         = 1
  cluster_type         = "regional"
  admin_user           = random_password.admin_username.result
  admin_password       = random_password.password.result
  db_name              = random_password.db_name.result
  db_port              = 3306
  vpc_id               = var.vpc_id
  security_groups      = var.security_groups
  subnets              = var.database_subnets
  enable_http_endpoint = true

  tags = { Name = "${var.tag_env}-rds" }
}

resource "aws_ssm_parameter" "db_name" {
  name  = "/${var.tag_env}/rds/db_name"
  type  = "SecureString"
  value = random_password.db_name.result
}

resource "aws_ssm_parameter" "endpoint" {
  name  = "/${var.tag_env}/rds/endpoint"
  type  = "SecureString"
  value = module.this.endpoint
}

resource "aws_ssm_parameter" "password" {
  name  = "/${var.tag_env}/rds/password"
  type  = "SecureString"
  value = random_password.password.result
}

resource "aws_ssm_parameter" "admin_username" {
  name  = "/${var.tag_env}/rds/username"
  type  = "SecureString"
  value = random_password.admin_username.result
}
