# VARIABLES

variable "aws_region" {
  description = "AWS region"
  default     = "ap-south-1"
}

variable "environment" {
  description = "Environment prefix"
  default     = "prod"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  default = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "db_name" {
  default = "wordpress"
}

variable "db_username" {
  default = "prodadm"
}

variable "db_password" {
  description = "RDS master password — set in terraform.tfvars only"
  sensitive   = true
}

variable "instance_type" {
  default = "t3.micro"
}

variable "acm_certificate_arn" {
  description = "ACM cert ARN for ALB (ap-south-1)"
  type        = string
}

variable "acm_certificate_arn_us_east_1" {
  description = "ACM cert ARN for CloudFront (us-east-1)"
  type        = string
}

variable "github_connection_arn" {
  description = "CodeStar GitHub connection ARN"
  type        = string
}

variable "github_repo" {
  description = "GitHub repo in format: username/repo-name"
  type        = string
}
