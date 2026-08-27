module "this" {
  source       = "terraform-aws-modules/dynamodb-table/aws"
  version      = "~> 4.2"
  create_table = true

  name     = "${var.tag_env}-pdf-files-per-user-descriptors"
  hash_key = "username"
  attributes = [
    { name = "username", type = "S" }
  ]

  tags = { Environment = var.tag_env }
}

resource "aws_ssm_parameter" "table_name" {
  name  = "/${var.tag_env}/dynamodb/table_name"
  type  = "SecureString"
  value = module.this.dynamodb_table_id
}
