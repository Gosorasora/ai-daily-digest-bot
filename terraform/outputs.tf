output "sns_topic_arn" {
  description = "Subscribe audience emails to this ARN"
  value       = aws_sns_topic.digest.arn
}

output "lambda_name" {
  description = "Lambda function name (for manual invoke)"
  value       = aws_lambda_function.digest.function_name
}

output "lambda_log_group" {
  description = "CloudWatch log group for Lambda"
  value       = aws_cloudwatch_log_group.lambda.name
}

output "schedule_rule" {
  description = "EventBridge rule name"
  value       = aws_cloudwatch_event_rule.daily.name
}

output "subscribe_command" {
  description = "Copy-paste command to subscribe an email address"
  value       = "aws sns subscribe --topic-arn ${aws_sns_topic.digest.arn} --protocol email --notification-endpoint YOUR_EMAIL@example.com"
}

output "manual_invoke_command" {
  description = "Copy-paste command to fire the Lambda manually"
  value       = "aws lambda invoke --function-name ${aws_lambda_function.digest.function_name} --payload '{}' /tmp/out.json && cat /tmp/out.json"
}
