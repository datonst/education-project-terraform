output "auth_lambda_arn" {
  description = "ARN of the authentication Lambda function with version"
  value       = "${aws_lambda_function.auth_lambda.arn}:${aws_lambda_function.auth_lambda.version}"
}


output "lambda_edge_role_arn" {
  description = "ARN of the Lambda@Edge IAM role"
  value       = aws_iam_role.lambda_edge_role.arn
}
