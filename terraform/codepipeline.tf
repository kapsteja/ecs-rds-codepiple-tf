# ---------------------------------------------------------------------------------------------------------------------
# Code Pipeline
# ---------------------------------------------------------------------------------------------------------------------

# CodePipeline IAM Role
resource "aws_iam_role" "codepipeline_role" {
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "codepipeline.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
  path = "/"
}

# IAM Policy for CodePipeline
resource "aws_iam_policy" "codepipeline_policy" {
  description = "Policy to allow CodePipeline to execute"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:GetObject", "s3:GetObjectVersion", "s3:PutObject",
        "s3:GetBucketVersioning"
      ],
      "Effect": "Allow",
      "Resource": "${aws_s3_bucket.artifact_bucket.arn}/*"
    },
    {
      "Action": [
        "codebuild:StartBuild", "codebuild:BatchGetBuilds",
        "cloudformation:*",
        "iam:PassRole"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Action": [
        "ecs:*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "codepipeline-attach" {
  role       = aws_iam_role.codepipeline_role.name
  policy_arn = aws_iam_policy.codepipeline_policy.arn
}

# S3 Bucket for Artifacts
resource "aws_s3_bucket" "artifact_bucket" {
  bucket = "your-unique-artifact-bucket-name"
  acl    = "private"
}

# CodePipeline
resource "aws_codepipeline" "pipeline" {
  depends_on = [
    aws_codebuild_project.codebuild
  ]
  name     = "${var.source_repo_name}-${var.source_repo_branch}-Pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.artifact_bucket.bucket
    type     = "S3"
  }

  # Source Stage - GitHub
  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "ThirdParty"
      version          = "1"
      provider         = "GitHub"
      output_artifacts = ["SourceOutput"]
      run_order        = 1

      configuration = {
        Owner      = var.github_owner
        Repo       = var.github_repo
        Branch     = var.github_branch
        OAuthToken = var.github_token
      }
    }
  }

  # Build Stage
  stage {
    name = "Build"
    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      version          = "1"
      provider         = "CodeBuild"
      input_artifacts  = ["SourceOutput"]
      output_artifacts = ["BuildOutput"]
      run_order        = 1
      configuration = {
        ProjectName = aws_codebuild_project.codebuild.name
      }
    }
  }

  # Deploy Stage
  stage {
    name = "Deploy"
    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      version         = "1"
      provider        = "ECS"
      run_order       = 1
      input_artifacts = ["BuildOutput"]
      configuration = {
        ClusterName       = "${var.stack}-Cluster"
        ServiceName       = "${var.stack}-Service"
        FileName          = "imagedefinitions.json"
        DeploymentTimeout = "15"
      }
    }
  }
}

# Output the pipeline URL
output "pipeline_url" {
  value = "https://console.aws.amazon.com/codepipeline/home?region=${var.aws_region}#/view/${aws_codepipeline.pipeline.id}"
}
