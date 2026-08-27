data "aws_availability_zones" "available" {}

module "this" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.16"

  name = "${var.tag_env}-VPC"
  cidr = var.cidr

  azs              = slice(data.aws_availability_zones.available.names, 0, 2)
  private_subnets  = var.private_subnets
  public_subnets   = var.public_subnets
  database_subnets = var.database_subnets

  enable_nat_gateway                 = true
  single_nat_gateway                 = true
  create_database_subnet_route_table = false

  tags                 = { Name = "${var.tag_env}-VPC" }
  public_subnet_tags   = { Name = "${var.tag_env}-Public-Subnet" }
  private_subnet_tags  = { Name = "${var.tag_env}-Private-Subnet" }
  database_subnet_tags = { Name = "${var.tag_env}-Database-Subnet" }
}
