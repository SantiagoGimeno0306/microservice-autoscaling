provider "aws" {
  region = var.aws_region
}

resource "aws_iam_role" "ec2_read_s3" {
  name = "ec2_read_s3"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "ec2_read_s3" {
  name = "ec2_read_s3_policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::sgimeno-main-bucket",
          "arn:aws:s3:::sgimeno-main-bucket/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach" {
  role       = aws_iam_role.ec2_read_s3.name
  policy_arn = aws_iam_policy.ec2_read_s3.arn
}

resource "aws_iam_instance_profile" "this" {
  name = "ec2_read_s3_profile"
  role = aws_iam_role.ec2_read_s3.name
}

module "s3_logs" {
  source = "terraform-aws-modules/s3-bucket/aws"
  tags = {
    Name = "main-s3"
  }
  bucket = "sgimeno-main-bucket"
  lifecycle_rule = [{
    id     = "auto_delete_rule"
    status = "Enabled"

    expiration = {
      days = 30
    }
  }]
}

resource "aws_ecr_repository" "ecr_users_repo" {
  name = "users-service"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
  
}

resource "aws_ecr_lifecycle_policy" "ecr_users_repo_policy" {
  repository = aws_ecr_repository.ecr_users_repo.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire untagged images after 1 hour"
        selection    = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "hours"
          countNumber = 1
        }
        action       = {
          type = "expire"
        }
      }
    ]
  })
}