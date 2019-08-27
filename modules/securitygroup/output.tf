output "security_group" {
  description = "Security Group LB"
  value       =  "${aws_security_group.lb.id}"
}

output "security_group_ecs" {
  description = "Security Group ECS"
  value       =  "${aws_security_group.ecs_tasks.id}"
}