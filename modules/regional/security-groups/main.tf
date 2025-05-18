//security.tf
resource "aws_security_group" "main" {
  name   = var.sg_name
  vpc_id = var.vpc_id

  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      cidr_blocks = ingress.value.cidr_blocks
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
    }
  }

  dynamic "egress" {
    for_each = var.egress_rules
    content {
      cidr_blocks = egress.value.cidr_blocks
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
    }
  }
  lifecycle {
    create_before_destroy = true
  }
}
