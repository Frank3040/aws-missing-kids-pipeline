output "starter_lambda_role_arn" { value = aws_iam_role.starter_lambda.arn }
output "validator_lambda_role_arn" { value = aws_iam_role.validator_lambda.arn }
output "transformer_lambda_role_arn" { value = aws_iam_role.transformer_lambda.arn }
output "sfn_role_arn" { value = aws_iam_role.sfn.arn }
output "glue_role_arn" { value = aws_iam_role.glue.arn }
