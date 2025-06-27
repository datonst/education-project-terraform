# SSM Parameters for application configuration
resource "aws_ssm_parameter" "parameters" {
  for_each = var.parameters

  name        = each.key
  type        = each.value.type
  value       = each.value.value
  description = try(each.value.description, "Parameter for ${each.key}")

  tags = var.tags

  # Encrypt SecureString parameters
  key_id = each.value.type == "SecureString" ? try(each.value.key_id, "alias/aws/ssm") : null
}
