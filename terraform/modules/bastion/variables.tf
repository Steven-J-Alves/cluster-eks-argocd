variable "tag_env" { type = string }
variable "vpc_id" { type = string }
variable "public_subnets" { type = list(string) }
variable "public_key" { type = string }

variable "instance_type" {
  type    = string
  default = "t3.small"
}
