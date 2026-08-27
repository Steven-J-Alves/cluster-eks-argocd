module "lambda_iam" {
  source             = "../modules/iam-lambda"
  tag_env            = var.tag_env
  aws_region         = var.aws_region
  sqs_queue_arn      = module.sqs.queue_arn
  s3_bucket_arn      = module.s3.bucket_arn
  dynamodb_table_arn = module.dynamodb.table_arn
}
