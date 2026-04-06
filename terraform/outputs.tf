output "vpc_id" {
  value       = aws_vpc.main.id
  description = "Main VPC ID"
}

output "alb_dns_name" {
  value       = aws_lb.main.dns_name
  description = "Open in browser to test"
}

output "ecr_repo_url" {
  value       = aws_ecr_repository.wordpress.repository_url
  description = "ECR repository URL for Docker image push"
}

output "efs_id" {
  value       = aws_efs_file_system.wordpress.id
  description = "EFS file system ID"
}

output "secret_name" {
  value       = aws_secretsmanager_secret.wordpress_db.name
  description = "Secrets Manager secret name for WordPress DB"
}

output "pipeline_name" {
  value       = aws_codepipeline.wordpress.name
  description = "CodePipeline name"
}

#output "cloudfront_dr" {
#  value       = aws_cloudfront_distribution.dr.domain_name
#  description = "CloudFront DR distribution domain"
#}

output "rds_endpoint" {
  value       = aws_db_instance.wordpress.address
  description = "RDS MySQL endpoint address"
  sensitive   = true
}
