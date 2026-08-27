module "this" {
  source  = "cloudposse/ecr/aws"
  version = "~> 0.42"

  name                 = "${var.tag_env}-ecr"
  image_names          = [for n in var.image_names : "${var.tag_env}/${n}"]
  use_fullname         = true
  force_delete         = true
  image_tag_mutability = "MUTABLE"
}
