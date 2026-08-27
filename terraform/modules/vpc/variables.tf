variable "tag_env" {
  type        = string
  description = "Environment tag (e.g. prod, dev)"
}

variable "cidr" {
  type        = string
  default     = "10.0.0.0/16"
  description = "VPC CIDR block"
}

variable "private_subnets" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "public_subnets" {
  type    = list(string)
  default = ["10.0.4.0/24", "10.0.5.0/24"]
}

variable "database_subnets" {
  type    = list(string)
  default = ["10.0.41.0/24", "10.0.42.0/24"]
}
