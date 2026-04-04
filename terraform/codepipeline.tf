# ── S3: Pipeline Artifacts ────────────────────────────────────
resource "aws_s3_bucket" "pipeline_artifacts" {
  bucket = "ganeshc-codepipeline-artifacts"
  tags   = { Name = "${var.environment}-pipeline-artifacts" }
}

resource "aws_s3_bucket_versioning" "pipeline_artifacts" {
  bucket = aws_s3_bucket.pipeline_artifacts.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_public_access_block" "pipeline_artifacts" {
  bucket                  = aws_s3_bucket.pipeline_artifacts.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ── CodeBuild: Terraform + Docker + ECR ──────────────────────
resource "aws_codebuild_project" "wordpress" {
  name          = "wordpress-build"
  description   = "Run Terraform + Build Docker image + Push to ECR"
  service_role  = aws_iam_role.codebuild_role.arn
  build_timeout = 30

  source {
    type      = "CODEPIPELINE"
    buildspec = "cicd/buildspec.yml"
  }

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/standard:7.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true   # Required for Docker builds

    environment_variable {
      name  = "ECR_REPO_URL"
      value = aws_ecr_repository.wordpress.repository_url
    }
    environment_variable {
      name  = "AWS_REGION_NAME"
      value = var.aws_region
    }
    # DB password passed securely via Secrets Manager reference
    environment_variable {
      name  = "SECRET_NAME"
      value = aws_secretsmanager_secret.wordpress_db.name
    }
    # Terraform vars passed as env vars — not in command line
    environment_variable {
      name  = "TF_VAR_db_password"
      value = var.db_password
      type  = "PLAINTEXT"
    }
    environment_variable {
      name  = "TF_VAR_acm_certificate_arn"
      value = var.acm_certificate_arn
    }
    environment_variable {
      name  = "TF_VAR_acm_certificate_arn_us_east_1"
      value = var.acm_certificate_arn_us_east_1
    }
    environment_variable {
      name  = "TF_VAR_github_connection_arn"
      value = var.github_connection_arn
    }
    environment_variable {
      name  = "TF_VAR_github_repo"
      value = var.github_repo
    }
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "/codebuild/wordpress"
      stream_name = "build-log"
    }
  }

  tags = { Name = "${var.environment}-codebuild" }
}

# ── CodeDeploy Application ────────────────────────────────────
resource "aws_codedeploy_app" "wordpress" {
  name             = "wordpress-app"
  compute_platform = "Server"
}

# ── CodeDeploy Deployment Group — Blue/Green ──────────────────
resource "aws_codedeploy_deployment_group" "wordpress" {
  app_name              = aws_codedeploy_app.wordpress.name
  deployment_group_name = "wordpress-prod-dg"
  service_role_arn      = aws_iam_role.codedeploy_role.arn

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  blue_green_deployment_config {
    # Green instances auto-created from ASG copy
    green_fleet_provisioning_option {
      action = "COPY_AUTO_SCALING_GROUP"
    }

    # Switch traffic immediately after validate.sh passes
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }

    # Terminate Blue instances 5 mins after successful Green deployment
    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 5
    }
  }

  autoscaling_groups = [aws_autoscaling_group.wordpress.name]

  # ALB controls Blue → Green traffic shift
  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [aws_lb_listener.https.arn]
      }
      target_group { name = aws_lb_target_group.blue.name }
      target_group { name = aws_lb_target_group.green.name }
    }
  }

  # Auto rollback to Blue if health check fails
  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE", "DEPLOYMENT_STOP_ON_ALARM"]
  }

  deployment_config_name = "CodeDeployDefault.OneAtATime"
  tags = { Name = "${var.environment}-codedeploy-bg" }
}

# ── CodePipeline ──────────────────────────────────────────────
resource "aws_codepipeline" "wordpress" {
  name     = "wordpress-prod-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.pipeline_artifacts.bucket
    type     = "S3"
  }

  # ── Stage 1: Source — GitHub ──────────────────────────────
  stage {
    name = "Source"
    action {
      name             = "GitHub_Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]
      configuration = {
        ConnectionArn    = var.github_connection_arn
        FullRepositoryId = var.github_repo
        BranchName       = "main"
        DetectChanges    = "true"
      }
    }
  }

  # ── Stage 2: Build — Terraform + Docker + ECR ────────────
  stage {
    name = "Build"
    action {
      name             = "Terraform_Docker_Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      configuration = {
        ProjectName = aws_codebuild_project.wordpress.name
      }
    }
  }

  # ── Stage 3: Deploy — Blue/Green ─────────────────────────
  stage {
    name = "Deploy"
    action {
      name            = "BlueGreen_Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeploy"
      version         = "1"
      input_artifacts = ["build_output"]
      configuration = {
        ApplicationName     = aws_codedeploy_app.wordpress.name
        DeploymentGroupName = aws_codedeploy_deployment_group.wordpress.deployment_group_name
      }
    }
  }

  tags = { Name = "${var.environment}-pipeline" }
}
