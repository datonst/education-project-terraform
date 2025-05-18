resource "aws_lb" "lb" {
  name               = var.lb_name
  subnets            = var.subnet_ids
  security_groups    = var.security_group_ids
  internal           = var.internal
  tags               = merge({ "Name" = "${var.cluster_name}-${var.lb_name}" }, var.common_tags)
  load_balancer_type = var.load_balancer_type
}
