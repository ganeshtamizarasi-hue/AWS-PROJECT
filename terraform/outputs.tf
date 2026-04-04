output "vpc_id"           { value = aws_vpc.main.id }
output "alb_dns_name"     { value = aws_lb.main.dns_name; description = "Open in browser to test" }
output "ecr_repo_url"     { value = aws_ecr_repository.wordpress.repository_url }
output "efs_id"           { value = aws_efs_file_system.wordpress.id }
output "secret_name"      { value = aws_secretsmanager_secret.wordpress_db.name }
output "pipeline_name"    { value = aws_codepipeline.wordpress.name }
output "cloudfront_dr"    { value = aws_cloudfront_distribution.dr.domain_name }
output "rds_endpoint"     { value = aws_db_instance.wordpress.address; sensitive = true }
