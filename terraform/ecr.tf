#   ECR REPOSITORY FOLDER
resource "aws_ecr_repository" "wordpress" {
  name                 = "${var.environment}-wordpress"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
  tags = { Name = "${var.environment}-wordpress-ecr" }
}

resource "aws_ecr_lifecycle_policy" "wordpress" {
  repository = aws_ecr_repository.wordpress.name
  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 10 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
      action = { type = "expire" }
    }]
  })
}
