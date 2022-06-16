locals {
  id = replace(var.name, " ", "-")
}

# --------------------------------------------------------
# CREATE New Service
# --------------------------------------------------------

resource "aws_ecr_repository" "this" {
  count = length(var.repositories)
  name  = lower(element(values(var.repositories), count.index))
}

resource "aws_ecs_task_definition" "this" {
  count = var.network_mode != "awsvpc" ? 1 : 0
  family  = local.id
  container_definitions = data.template_file.this.rendered
  dynamic "volume" {
    for_each = var.volumes
    content {
      name      = volume.value.name
      host_path = volume.value.host_path
    }
  }

  task_role_arn = aws_iam_role.this.arn
  execution_role_arn = var.enable_ssm ? aws_iam_role.this.arn : ""
  requires_compatibilities = var.compatibilities
  dynamic "placement_constraints" {
    for_each = var.placement_constraints.type != "" ? list(var.placement_constraints) : []
    content {
       type       = var.placement_constraints.type
       expression = var.placement_constraints.expression
    }
  }
}

resource "aws_ecs_task_definition" "private" {
  count = var.network_mode == "awsvpc" ? 1 : 0
  family                = local.id
  container_definitions = data.template_file.this.rendered
  dynamic "volume" {
    for_each = length(var.volumes) > 0 ? list(var.volumes) : []

    content {
      name      = var.volumes.name != "" ? var.volumes.name : ""
      host_path = var.volumes.host_path != "" ? var.volumes.host_path : ""
    }
  }
  # Old Definition for 0.11.x
  #volume {
  #  name      = var.volumes.name
  #  host_path = var.volumes.host_path
  #}
  task_role_arn = aws_iam_role.this.arn
  execution_role_arn = aws_iam_role.this.arn
  requires_compatibilities = var.compatibilities
  network_mode = var.network_mode
}



resource "aws_ecs_service" "this" {
  count = var.balancer["name"] != "" && var.cluster != "" && var.network_mode != "awsvpc" && var.health_check.protocol == "TCP" ? 1 : 0
  name            = local.id
  cluster         = var.cluster
  task_definition = aws_ecs_task_definition.this.0.arn
  desired_count   = var.desired
  iam_role        = data.aws_iam_role.service_ecs.arn
  health_check_grace_period_seconds = 0

  load_balancer {
    target_group_arn = var.target_group != "" ? var.target_group : aws_alb_target_group.this.0.arn
    container_name = var.balancer["container_name"]
    container_port = var.balancer["container_port"]
  }

  ordered_placement_strategy {
    type  = "spread"
    field = "host"
  }
}

resource "aws_ecs_service" "default" {
  count = var.balancer["name"] != "" && var.cluster != "" && var.network_mode != "awsvpc" && var.health_check.protocol != "TCP" ? 1 : 0
  name            = local.id
  cluster         = var.cluster
  task_definition = aws_ecs_task_definition.this.0.arn
  desired_count   = var.desired
  iam_role        = data.aws_iam_role.service_ecs.arn
  health_check_grace_period_seconds = 0

  load_balancer {
    target_group_arn = var.target_group != "" ? var.target_group : aws_alb_target_group.default.0.arn
    container_name = var.balancer["container_name"]
    container_port = var.balancer["container_port"]
  }

  ordered_placement_strategy {
    type  = "spread"
    field = "host"
  }
}

resource "aws_ecs_service" "private" {
  count = var.balancer["name"] != "" && var.cluster != "" && var.network_mode == "awsvpc" ? 1 : 0
  name            = local.id
  cluster         = var.cluster
  task_definition = aws_ecs_task_definition.private.0.arn
  desired_count   = var.desired
  #iam_role       = "aws-service-role"
  health_check_grace_period_seconds = 0

  load_balancer {
    target_group_arn = var.health_check.protocol != "TCP" ? aws_alb_target_group.default.0.arn : aws_alb_target_group.this.0.arn
    container_name = var.balancer["container_name"]
    container_port = var.balancer["container_port"]
  }

  service_registries {
    registry_arn = var.registry != "" ? var.registry : ""
    container_name = var.registry != "" ? var.balancer["container_port"] : ""
  }

  network_configuration {
    subnets = var.subnets
    security_groups = [var.security_group]
  }

  ordered_placement_strategy {
    type  = "spread"
    field = "host"
  }
}

resource "aws_ecs_service" "no_balancer" {
  count = var.balancer["name"] != "" || var.cluster == "" ? 0 : 1
  name            = local.id
  cluster         = var.cluster
  task_definition = aws_ecs_task_definition.this.0.arn
  desired_count   = var.desired
  health_check_grace_period_seconds = 0

  ordered_placement_strategy {
    type  = "spread"
    field = "host"
  }
}

resource "aws_iam_role" "this" {
  name = local.id
  description = "${var.name} ECSTask"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

module "logs" {
  source  = "Aplyca/cloudwatchlogs/aws"
  version = "0.3.1"

  name    = local.id
  role = aws_iam_role.this.name
  description = "${var.name} ECSTask CloudWatch Logs"
  tags = merge(var.tags, map("Name", var.name))
}


resource "aws_ssm_parameter" "parameters" {
  count = length(var.parameters)
  description = element(var.parameters, count.index).description
  name  = "${local.id}-${element(var.parameters, count.index).name}"
  type  = "String"
  value = " "
  lifecycle {
    ignore_changes = [
      value
    ]
  }
}

resource "aws_iam_policy" "ssm_parameter_store" {
  name   = "${local.id}-SSMParameterStore"
  description = "Access to SSM Parameter Store for ${local.id} parameters only"
  policy = data.aws_iam_policy_document.ssm_parameter_store.json
}

resource "aws_iam_role_policy_attachment" "ssm_parameter_store" {
  role = aws_iam_role.this.name
  policy_arn = aws_iam_policy.ssm_parameter_store.arn
}

resource "aws_iam_policy" "ecr" {
  name   = "${local.id}-ECR"
  description = "Access to ECR for ${local.id}"
  policy = data.aws_iam_policy_document.ecr.json
}

resource "aws_iam_role_policy_attachment" "ecr" {
  role = aws_iam_role.this.name
  policy_arn = aws_iam_policy.ecr.arn
}

resource "aws_alb_target_group" "default" {
  count = var.balancer["name"] != "" && var.health_check.protocol != "TCP" ? 1 : 0
  name     = local.id
  port     = 80
  protocol = var.proto_http ? "HTTP" : "TCP"
  vpc_id = data.aws_alb.this.vpc_id
  deregistration_delay = 3
  target_type = var.target_type

  dynamic "health_check" {
    for_each = var.health_check.protocol == "TCP" ? [] : list(var.health_check)
    
    content {
      port = "traffic-port"
      path = var.health_check["path"]
      healthy_threshold = var.health_check["healthy_threshold"]
      unhealthy_threshold = var.health_check["unhealthy_threshold"]
      interval = var.health_check["interval"]
      timeout = var.health_check["timeout"]      
      protocol = var.health_check["protocol"]
    }
  }

  tags = merge(var.tags, map("Name", var.name))
}

resource "aws_alb_target_group" "this" {
  count = var.balancer["name"] != "" && var.health_check.protocol == "TCP" ? 1 : 0
  name     = local.id
  port     = 80
  protocol = var.proto_http ? "HTTP" : "TCP"
  vpc_id = data.aws_alb.this.vpc_id
  deregistration_delay = 3
  target_type = var.target_type

  dynamic "health_check" {
    for_each = var.health_check.protocol == "TCP" ? [] : list(var.health_check)
    
    content {
      port = "traffic-port"
      healthy_threshold = health_check["healthy_threshold"]
      unhealthy_threshold = health_check["unhealthy_threshold"]
      protocol = health_check["protocol"]
    }
  }

  stickiness {
    type = "lb_cookie"
    enabled = false
  }
  tags = merge(var.tags, map("Name", var.name))  
}

resource "aws_lb_listener_rule" "http" {
  count = lookup(var.balancer, "condition_values", "") != ""? length(split(",", var.balancer["condition_values"])) : 0
  listener_arn = data.aws_alb_listener.http.arn
  #priority     = var.balancer["priority"] + count.index

  action {
    type             = "forward"
    target_group_arn = var.health_check.protocol != "TCP" ? aws_alb_target_group.default.0.arn : aws_alb_target_group.this.0.arn
  }

  condition {
    field  = var.balancer["condition_field"]
    values = [element(split(",", var.balancer["condition_values"]), count.index)]
  }

}

resource "aws_lb_listener_rule" "https" {
  count = lookup(var.balancer, "condition_values", "") != ""? length(split(",", var.balancer["condition_values"])) : 0
  listener_arn = data.aws_alb_listener.https.arn
  #priority     = var.balancer["priority"] + count.index

  action {
    type             = "forward"
    target_group_arn = var.health_check.protocol != "TCP" ? aws_alb_target_group.default.0.arn : aws_alb_target_group.this.0.arn
  }

  condition {
    field  = var.balancer["condition_field"]
    values = [element(split(",", var.balancer["condition_values"]), count.index)]
  }

}
