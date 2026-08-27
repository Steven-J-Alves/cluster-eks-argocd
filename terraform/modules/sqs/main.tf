module "this" {
  source  = "terraform-aws-modules/sqs/aws"
  version = "~> 4.2"

  content_based_deduplication = true
  fifo_queue                  = true
  visibility_timeout_seconds  = 360
  name                        = "${var.tag_env}-conversion-to-pdf-"
  use_name_prefix             = true
  create                      = true
}

resource "aws_ssm_parameter" "arn" {
  name  = "/${var.tag_env}/sqs/arn"
  type  = "SecureString"
  value = module.this.queue_arn
}

resource "aws_ssm_parameter" "name" {
  name  = "/${var.tag_env}/sqs/name"
  type  = "SecureString"
  value = module.this.queue_name
}

resource "aws_ssm_parameter" "url" {
  name  = "/${var.tag_env}/sqs/url"
  type  = "SecureString"
  value = module.this.queue_id
}
