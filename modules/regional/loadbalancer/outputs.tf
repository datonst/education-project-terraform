output "enpoint_alb" {
  value = aws_lb.lb.dns_name
}

output "lb_arn" {
  value = aws_lb.lb.arn
}
