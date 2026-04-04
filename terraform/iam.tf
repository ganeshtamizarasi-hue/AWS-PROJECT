# ═══════════════════════════════════════════════════════
# EC2 IAM Role
# ═══════════════════════════════════════════════════════
resource "aws_iam_role" "ec2_role" {
  name = "prod-ec2-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{ Action = "sts:AssumeRole"; Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" } }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
resource "aws_iam_role_policy_attachment" "s3" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}
resource "aws_iam_role_policy_attachment" "secrets" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
}
resource "aws_iam_role_policy_attachment" "codedeploy_ec2" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforAWSCodeDeploy"
}
resource "aws_iam_role_policy_attachment" "ecr_pull" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "prod-ec2-instance-profile"
  role = aws_iam_role.ec2_role.name
}

# ═══════════════════════════════════════════════════════
# CodeBuild IAM Role
# ═══════════════════════════════════════════════════════
resource "aws_iam_role" "codebuild_role" {
  name = "codebuild-wordpress-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{ Action = "sts:AssumeRole"; Effect = "Allow"
      Principal = { Service = "codebuild.amazonaws.com" } }]
  })
}

resource "aws_iam_role_policy" "codebuild_policy" {
  name = "codebuild-wordpress-policy"
  role = aws_iam_role.codebuild_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      { Effect = "Allow"; Action = ["s3:*"];              Resource = "*" },
      { Effect = "Allow"; Action = ["ecr:*"];             Resource = "*" },
      { Effect = "Allow"; Action = ["logs:*"];            Resource = "*" },
      { Effect = "Allow"; Action = ["secretsmanager:*"]; Resource = "*" },
      # Full access needed for terraform apply inside CodeBuild
      { Effect = "Allow"; Action = ["*"];                 Resource = "*" }
    ]
  })
}

# ═══════════════════════════════════════════════════════
# CodePipeline IAM Role
# ═══════════════════════════════════════════════════════
resource "aws_iam_role" "codepipeline_role" {
  name = "codepipeline-wordpress-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{ Action = "sts:AssumeRole"; Effect = "Allow"
      Principal = { Service = "codepipeline.amazonaws.com" } }]
  })
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  name = "codepipeline-wordpress-policy"
  role = aws_iam_role.codepipeline_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      { Effect = "Allow"; Action = ["s3:*"];                          Resource = "*" },
      { Effect = "Allow"; Action = ["codebuild:*"];                   Resource = "*" },
      { Effect = "Allow"; Action = ["codedeploy:*"];                  Resource = "*" },
      { Effect = "Allow"; Action = ["codestar-connections:UseConnection"]; Resource = "*" }
    ]
  })
}

# ═══════════════════════════════════════════════════════
# CodeDeploy IAM Role
# ═══════════════════════════════════════════════════════
resource "aws_iam_role" "codedeploy_role" {
  name = "CodeDeployServiceRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{ Action = "sts:AssumeRole"; Effect = "Allow"
      Principal = { Service = "codedeploy.amazonaws.com" } }]
  })
}

resource "aws_iam_role_policy_attachment" "codedeploy_policy" {
  role       = aws_iam_role.codedeploy_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
}
