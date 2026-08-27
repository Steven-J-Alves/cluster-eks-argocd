variable "tag_env" { type = string }
variable "vpc_id" { type = string }
variable "database_subnets" { type = list(string) }
variable "security_groups" { type = list(string) }
