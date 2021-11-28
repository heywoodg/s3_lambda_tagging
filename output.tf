output "lambda_role_name" {
  value = aws_iam_role.s3_lambda_role.name
}

output "lambda_role_arn" {
  value = aws_iam_role.s3_lambda_role.arn
}

output "aws_iam_policy_lambda_logging_arn" {
  value = aws_iam_policy.lambda_logging.arn
}

output "aws_s3_bucket_arn" {
  value = aws_s3_bucket.bucket.arn
}