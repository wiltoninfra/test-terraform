# ALB Security Group: Edit to restrict access to the application
resource "aws_security_group" "lb" {
  name        = "app-load-balancer"
  description = "controls access to the ALB"
  vpc_id      = "${var.vpcid}"

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Traffic to the ECS cluster should only come from the ALB
resource "aws_security_group" "ecs_tasks" {
  name        = "app-ecs"
  description = "allow inbound access from the ALB only"
  vpc_id      = "${var.vpcid}"

  ingress {
    protocol        = "tcp"
    from_port       = 80
    to_port         = 80
    security_groups = ["aws_security_group.lb.id"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}