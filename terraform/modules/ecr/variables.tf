variable "tag_env" { type = string }

variable "image_names" {
  type    = list(string)
  default = ["api", "ui", "lambda"]
}
