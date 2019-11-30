data "template_file" "this" {
    template = file(var.definition_file)
    vars = merge(var.definition_vars, zipmap(keys(var.repositories), aws_ecr_repository.this.*.repository_url), map("log_group", module.logs.name), map("region", data.aws_region.current.name), zipmap(keys(var.parameters), aws_ssm_parameter.parameters.*.arn))
}

data "aws_iam_policy_document" "ssm_parameter_store" {
  statement {
    actions = ["ssm:DescribeParameters"]

    resources = ["*"]
  }

  statement {
    actions = [
      "ssm:GetParameters",
    ]

    resources = [
      "arn:aws:ssm:*:*:parameter/${local.id}-*",
    ]
  }
}

data "aws_iam_policy_document" "ecr" {
  statement {
    actions = [
      "ecr:GetAuthorizationToken"
    ]

    resources = ["*"]
  }  
  statement {
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer"
    ]

    resources = aws_ecr_repository.this.*.arn
  }
}

data "aws_iam_role" "service_ecs" {
  name = "AWSServiceRoleForECS"
}

data "aws_alb" "this" {
  name = var.balancer["name"]
}

data "aws_alb_listener" "https" {
  load_balancer_arn = data.aws_alb.this.arn
  port              = 443
}

data "aws_alb_listener" "http" {
  load_balancer_arn = data.aws_alb.this.arn
  port              = 80
}

data "aws_region" "current" {}