provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

resource "aws_iam_role" "ec2_read" {
  name = "ec2_read"

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
  role       = aws_iam_role.ec2_read.name
  policy_arn = aws_iam_policy.ec2_read_s3.arn
}

/* resource "aws_iam_policy" "ec2_read_ecr" {
  name = "ec2_read_ecr_policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Effect" : "Allow",
        "Action" : "ecr:GetAuthorizationToken",
        "Resource" : "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = [
          "arn:aws:ecr:us-east-1:${data.aws_caller_identity.current.account_id}:repository/users-service",
          "arn:aws:ecr:us-east-1:${data.aws_caller_identity.current.account_id}:repository/users-service/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_ecr_ec2" {
  role       = aws_iam_role.ec2_read.name
  policy_arn = aws_iam_policy.ec2_read_ecr.arn
} */

resource "aws_iam_role_policy_attachment" "ecr" {
  role       = aws_iam_role.ec2_read.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_instance_profile" "this" {
  name = "ec2_read_s3_profile"
  role = aws_iam_role.ec2_read.name
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
  name                 = "users-service"
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
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 1
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
