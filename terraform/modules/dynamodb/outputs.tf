output "table_arn" {
  value = module.this.dynamodb_table_arn
}

output "table_name" {
  value = module.this.dynamodb_table_id
}
