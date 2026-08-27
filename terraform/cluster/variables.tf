variable "base_domain" {
  type        = string
  description = "Base DNS zone (e.g. argocd-lab.kriolu-kloud.cv)"
}

variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "AWS region"
}

variable "tag_env" {
  type        = string
  description = "Environment tag (e.g. dev, staging, qa, prod, dr)"
}

variable "vpc_cidr" {
  type        = string
  default     = "10.0.0.0/16"
  description = "VPC CIDR block. Use different blocks per env to allow future peering."
}

variable "eks_cluster_version" {
  type        = string
  default     = "1.31"
  description = "EKS Kubernetes version"
}

variable "node_instance_types" {
  type        = list(string)
  default     = ["t3.large"]
  description = "EC2 instance types for the managed node group"
}

variable "node_desired_size" {
  type        = number
  default     = 2
  description = "Desired number of nodes in the managed node group"
}

variable "id_rsa" {
  type        = string
  description = "Public SSH key for EC2 instances"
}

variable "datadog_api_key" {
  type    = string
  default = ""
}

variable "datadog_application_key" {
  type    = string
  default = ""
}

variable "datadog_region" {
  type    = string
  default = ""
}

variable "registrationToken" {
  type        = string
  description = "Token for GitHub Actions self-hosted runners (used by ARC)"
  sensitive   = true
}

variable "ci_project_repo" {
  type        = string
  description = "CI project repo path (e.g. org/repo)"
}

variable "cd_project_repo" {
  type        = string
  description = "CD (manifests) project repo path (e.g. org/repo)"
}

variable "gitlab_url" {
  type        = string
  default     = ""
  description = "Git host URL (GitLab or https://github.com)"
}

variable "gitlab_token" {
  type        = string
  default     = ""
  sensitive   = true
  description = "Token for ArgoCD to pull the manifests repo"
}
