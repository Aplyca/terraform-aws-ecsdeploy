locals {
  id = "${replace(var.name, " ", "-")}"
}

# --------------------------------------------------------
# CREATE New Service
# --------------------------------------------------------

resource "aws_ecr_repository" "this" {
  count = "${length(var.repositories)}"
  name  = "${lower(element(values(var.repositories), count.index))}"
}

resource "aws_ecs_task_definition" "this" {
  family                = "${local.id}"
  container_definitions = "${data.template_file.this.rendered}"
  volume = "${var.volumes}"
  task_role_arn = "${aws_iam_role.this.arn}"
  requires_compatibilities = ["${var.compatibilities}"]
}

resource "aws_alb_target_group" "this" {
  count = "${var.balancer["vpc_id"] != "" ? 1 : 0}"
  name     = "${local.id}"
  port     = 80
  protocol = "HTTP"
  vpc_id = "${var.balancer["vpc_id"]}"
  tags = "${merge(var.tags, map("Name", "${var.name}"))}"
  deregistration_delay = 3

  stickiness {
    type = "lb_cookie"
    enabled = false
  }
}

resource "aws_lb_listener_rule" "http" {
  count = "${lookup(var.balancer, "condition_values", "") != ""? length(split(",", var.balancer["condition_values"])) : 0}"
  listener_arn = "${var.balancer["listener_http"]}"
  priority     = "${var.balancer["priority"] + count.index}"

  action {
    type             = "forward"
    target_group_arn = "${aws_alb_target_group.this.0.arn}"
  }

  condition {
    field  = "${var.balancer["condition_field"]}"
    values = ["${element(split(",", var.balancer["condition_values"]), count.index)}"]
  }
}

resource "aws_lb_listener_rule" "https" {
  count = "${lookup(var.balancer, "condition_values", "") != ""? length(split(",", var.balancer["condition_values"])) : 0}"
  listener_arn = "${var.balancer["listener_https"]}"
  priority     = "${var.balancer["priority"] + count.index}"

  action {
    type             = "forward"
    target_group_arn = "${aws_alb_target_group.this.0.arn}"
  }

  condition {
    field  = "${var.balancer["condition_field"]}"
    values = ["${element(split(",", var.balancer["condition_values"]), count.index)}"]
  }
}

resource "aws_ecs_service" "this" {
  count = "${var.balancer["vpc_id"] != "" && var.cluster != "" ? 1 : 0}"
  name            = "${local.id}"
  cluster         = "${var.cluster}"
  task_definition = "${aws_ecs_task_definition.this.arn}"
  desired_count   = "${var.desired}"
  iam_role        = "arn:aws:iam::159895783284:role/aws-service-role/ecs.amazonaws.com/AWSServiceRoleForECS"
  health_check_grace_period_seconds = 0

  load_balancer {
    target_group_arn = "${aws_alb_target_group.this.0.arn}"
    container_name = "${var.balancer["container_name"]}"
    container_port = "${var.balancer["container_port"]}"
  }

  ordered_placement_strategy {
    type  = "spread"
    field = "host"
  }
}

resource "aws_ecs_service" "no_balancer" {
  count = "${var.balancer["vpc_id"] != "" || var.cluster == "" ? 0 : 1}"
  name            = "${local.id}"
  cluster         = "${var.cluster}"
  task_definition = "${aws_ecs_task_definition.this.arn}"
  desired_count   = "${var.desired}"
  iam_role        = "arn:aws:iam::159895783284:role/aws-service-role/ecs.amazonaws.com/AWSServiceRoleForECS"  
  health_check_grace_period_seconds = 0

  ordered_placement_strategy {
    type  = "spread"
    field = "host"
  }
}

resource "aws_iam_role" "this" {
  name = "${local.id}"
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
  version = "0.1.0"

  name    = "${local.id}"
  role = "${aws_iam_role.this.name}"
  description = "${var.name} ECSTask CloudWatch Logs"
  tags = "${merge(var.tags, map("Name", "${var.name}"))}"
}
