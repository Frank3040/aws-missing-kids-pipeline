output "starter_function_name" { value = aws_lambda_function.starter.function_name }
output "starter_function_arn" { value = aws_lambda_function.starter.arn }
output "validator_function_arn" { value = aws_lambda_function.validator.arn }
output "transformer_function_arn" { value = aws_lambda_function.transformer.arn }
# keep backward compat alias used by cloudwatch module
output "function_name" { value = aws_lambda_function.starter.function_name }
