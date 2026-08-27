data "aws_caller_identity" "current" {}

module "this" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.6"

  create_bucket            = true
  bucket                   = "${var.tag_env}-app-output-files-${data.aws_caller_identity.current.account_id}"
  acl                      = "private"
  control_object_ownership = true
  object_ownership         = "ObjectWriter"
  force_destroy            = true
}

resource "aws_ssm_parameter" "bucket_name" {
  name  = "/${var.tag_env}/s3_bucket/for_output_files/name"
  type  = "SecureString"
  value = module.this.s3_bucket_id
}
