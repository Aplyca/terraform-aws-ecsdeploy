# Terraform AWS ECS Deploy module

Deploy al necessary resources for ECS apps

# Example of service

```HCL
module "my_service" {
  source  = "Aplyca/ecsdeploy/aws"
  version = "0.3.0"

  name    = "MyService"
  cluster = "MYCLUSTER"
  desired = 1
  balancer = {
    name = "MyALB"
    container_name = "Web"
    container_port = 80
    condition_field  = "host-header"
    condition_values = ["mydomain.com"]
  }

  health_check = {
    path = "/"
    healthy_threshold = "5"
    unhealthy_threshold = "2"
    protocol = "HTTP"
  }

  repositories = {
    web-image = "myapp/web"
  }

  definition_file = "task.json"
  enable_ssm = true
  definition_vars = {
    web-version = "master"
  }

  parameters = {
    DATABASE_HOST = "Description of this parameter"
    DATABASE_USER = "Description of this parameter"
    DATABASE_PASSWORD = "Description of this parameter"
  }

  volumes = {
    name      = "MyApp-Storage"
    host_path = "/mnt/myapp-storage"
  }

  tags = {
    App = "MyApp"
    Environment = "Production"
    Service = "Web"
  }
}
```

## Sample data to use Service Discovery

This Role supports using Service Discovery

```
  network_mode = "awsvpc"
  registry = "${aws_service_discovery_service.example.arn}"
  target_type = "ip"
  subnets = ["subnet-1234","subnet-5678"]
  security_group = ["sg-12345"]
```

## Sample data to custom health checks

```
 health_check {
    health_check_path = "/example/#/"
    healthy_threshold = "15"
    unhealthy_threshold = "5"
  }
```

## Sample to use TCP instead of HTTP

```
  proto_http = false
```

## Sample to use an existing Target Group

```
  target_group = "arn:aws:elasticloadbalancing:us-east-1:11111111:targetgroup/mycustomtg/1111111"
```

## Sample to include Placement Constraints

```
   placement_constraints {
    type       = "memberOf"
    expression = "attribute:ecs.availability-zone in [us-east-1a]"
  }
```
