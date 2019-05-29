Terraform AWS ECS Deploy module
===============================

Deploy al necessary resources for ECS apps

This Role supports using Service Discovery

Sample data to use Service Discovery
------------------------------------
```
  network_mode = "awsvpc"
  registry = "${aws_service_discovery_service.example.arn}"
  target_type = "ip"
  subnets = ["subnet-1234","subnet-5678"]
  security_group = ["sg-12345"]
```

Sample data to custom health checks
-----------------------------------
```
 health_check {
    health_check_path = "/example/#/"
    healthy_threshold = "15"
    unhealthy_threshold = "5"
  }
```
