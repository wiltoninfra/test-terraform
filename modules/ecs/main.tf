
resource "aws_alb" "main" {
  name            = "app-load-balancer"
  subnets         = ["${var.public}"] 
  security_groups = ["${var.security-group}"]
}

resource "aws_alb_target_group" "app" {
  name        = "app-target-group"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = "${var.vpcid}"
  target_type = "ip"

  health_check {
    healthy_threshold   = "3"
    interval            = "30"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "3"
    path                = "${var.health_check_path}"
    unhealthy_threshold = "2"
  }
}

# Redirect all traffic from the ALB to the target group
resource "aws_alb_listener" "front_end" {
  load_balancer_arn = "aws_alb.main.id"
  port              = "${var.app_port}"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "aws_alb_target_group.app.id"
    type             = "forward"
  }
}

resource "aws_ecs_cluster" "main" {
  name = "app-cluster"
}


resource "aws_ecs_task_definition" "app" {
  family                   = "app-test"
  execution_role_arn       = "aws_iam_role.ecs_task_execution_role.arn"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "${var.fargate_cpu}"
  memory                   = "${var.fargate_memory}"
   container_definitions = <<DEFINITION
[
  {
    "cpu": 128,
    "environment": [{
      "name": "GERU_PASS",
      "value": "KEY"
    }],
    "essential": true,
    "image": "wilton/app-test:v1",
    "memory": 128,
    "memoryReservation": 64,
    "name": "app-test"
  }
]
DEFINITION
}


resource "aws_ecs_service" "main" {
  name            = "cb-service"
  cluster         = "aws_ecs_cluster.main.id"
  task_definition = "aws_ecs_task_definition.app.arn"
  desired_count   = "${var.app_count}"
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = ["${var.security-group_ecs}"]
    subnets          = ["${var.private}"]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = "aws_alb_target_group.app.id"
    container_name   = "cb-app"
    container_port   = "${var.app_port}"
  }

  depends_on = ["aws_alb_listener.front_end", "aws_iam_role_policy_attachment.ecs_task_execution_role"]
}

resource "aws_appautoscaling_target" "target" {
  service_namespace  = "ecs"
  resource_id        = "service/aws_ecs_cluster.main.name/aws_ecs_service.main.name"
  scalable_dimension = "ecs:service:DesiredCount"
  role_arn           = "aws_iam_role.ecs_auto_scale_role.arn"
  min_capacity       = 3
  max_capacity       = 6
}

# Automatically scale capacity up by one
resource "aws_appautoscaling_policy" "up" {
  name               = "cb_scale_up"
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.main.name}"
  scalable_dimension = "ecs:service:DesiredCount"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Maximum"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1
    }
  }

  depends_on = ["aws_appautoscaling_target.target"]
}

# Automatically scale capacity down by one
resource "aws_appautoscaling_policy" "down" {
  name               = "cb_scale_down"
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.main.name}"
  scalable_dimension = "ecs:service:DesiredCount"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Maximum"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = -1
    }
  }

  depends_on = ["aws_appautoscaling_target.target"]
}


resource "aws_iam_role" "ecs_task_execution_role" {
  name = "unifi_ecs_task_execution_role"

  assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role" {
  role       = "${aws_iam_role.ecs_task_execution_role.id}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
