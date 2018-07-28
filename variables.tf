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
    vpc_id  = ""
    condition_values = ""
    container_name = ""
    container_port = 0
  }
}

variable "volumes" {
  description = "Volumes"
  default = []
}

variable "desired" {
  description = "Desired count of tasks in service"
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
