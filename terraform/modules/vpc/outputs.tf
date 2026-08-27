output "vpc_id" {
  value = module.this.vpc_id
}

output "public_subnets" {
  value = module.this.public_subnets
}

output "private_subnets" {
  value = module.this.private_subnets
}

output "database_subnets" {
  value = module.this.database_subnets
}
