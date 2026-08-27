module "ecr" {
  source  = "../modules/ecr"
  tag_env = var.tag_env
}

module "s3" {
  source  = "../modules/s3"
  tag_env = var.tag_env
}

module "sqs" {
  source  = "../modules/sqs"
  tag_env = var.tag_env
}

module "dynamodb" {
  source  = "../modules/dynamodb"
  tag_env = var.tag_env
}
