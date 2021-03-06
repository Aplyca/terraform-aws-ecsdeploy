variable "aws_account" {
  description = "ID of AWS Account"
  default     = "*"
}

variable "name" {
  description = "Name prefix for all VPC resources."
  default     = "App"
}

variable "cluster" {
  description = "ECS cluster name"
  default = ""
}

variable "tags" {
  description = "A mapping of tags to assign to the resource."
  default     = {}
}

variable "definition_file" {
  description = "Container definition JSON file"
  default = ""
}

variable "definition_vars" {
  description = "Container definition vars"
  default = {}
}

variable "balancer" {
  description = "Listener configurations for ALB"
  default = {
    name = ""
    condition_values = ""
    container_name = ""
    container_port = 0
  }
}

variable "health_check" {
  type = map
  description = "Health checks for Target Group"
  default = {
    health_check_path = "/"
    healthy_threshold = "5"
    unhealthy_threshold = "2"
    interval = "30"
    timeout = "5"     
    protocol = "HTTP"
  }
}

variable "volumes" {
  type = list
  description = "List of Volumes used by the service"
  default = []
}

variable "desired" {
  description = "Desired count of tasks in service"
  default = 0
}

variable "grace_period" {
  description = "health_check_grace_period_seconds"
  default = 0
} 

variable "repositories" {
  description = "Images repositories"
  default = {}
}

variable "compatibilities" {
  description = "Requires compatibilities"
  default = []
}

variable "network_mode" {
  description = "The valid values are none, bridge, awsvpc, and host"
  default = "none"
}

variable "registry" {
  description = "The ARN for Service Discovery Registry"
  default = ""
}

variable "target_type" {
  description = "Target Type for Target Group"
  default = "instance"
}

variable "subnets" {
  type = list
  default = []
  description = "Used for Networking in Service Discovery"
}

variable "security_group" {
  description = "Used for Networking in Service Discovery"
  default = ""
}

variable "enable_ssm" {
  description = "Compatibility for old versions without support for SSM"
  default = false
}

variable "proto_http" {
  description = "Use HTTP Protocol by default for ALB Target Group"
  default = true
}

variable "target_group" {
  description = "Set existing Target Group for new service"
  default = ""
}

variable "placement_constraints" {
  description = "(Optional) A set of rules that are taken during task placement"
  #type        = "list"
  default = {
    type  = ""
    expression = ""
  }
}

variable "parameters" {
  type = list
  description = "List of parameters used by the service form Parameters Store"
  default = []
}