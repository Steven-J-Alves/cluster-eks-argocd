data "aws_caller_identity" "current" {}

module "role" {
  source                            = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version                           = "~> 5.50"
  create_role                       = true
  role_name                         = "${var.tag_env}-lambda-execution-role"
  create_instance_profile           = true
  role_requires_mfa                 = false
  trusted_role_services             = ["lambda.amazonaws.com"]
  custom_role_policy_arns           = [module.policy.arn]
  number_of_custom_role_policy_arns = 1
}

module "policy" {
  source      = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version     = "~> 5.50"
  name        = "${var.tag_env}-lambda-execution-policy"
  path        = "/"
  description = "For lambda execution"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["logs:CreateLogStream", "logs:CreateLogGroup"]
        Resource = ["arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/*"]
        Effect   = "Allow"
      },
      {
        Action   = ["logs:PutLogEvents"]
        Resource = ["arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/*"]
        Effect   = "Allow"
      },
      {
        Action   = ["sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes"]
        Resource = [var.sqs_queue_arn]
        Effect   = "Allow"
      },
      {
        Action   = "s3:*"
        Resource = [var.s3_bucket_arn, "${var.s3_bucket_arn}/*"]
        Effect   = "Allow"
      },
      {
        Action   = "dynamodb:*"
        Resource = var.dynamodb_table_arn
        Effect   = "Allow"
      }
    ]
  })
}

resource "aws_ssm_parameter" "role_arn" {
  name  = "/${var.tag_env}/lambda/iam/role/arn"
  type  = "SecureString"
  value = module.role.iam_role_arn
}
