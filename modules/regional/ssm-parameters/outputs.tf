output "parameter_arns" {
  description = "ARNs of the created SSM parameters"
  value = {
    for k, v in aws_ssm_parameter.parameters : k => v.arn
  }
}

output "parameter_names" {
  description = "Names of the created SSM parameters"
  value = {
    for k, v in aws_ssm_parameter.parameters : k => v.name
  }
}
