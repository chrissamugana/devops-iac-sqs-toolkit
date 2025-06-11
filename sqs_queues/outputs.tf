output "queue_arns" {
  value = concat(
    [for q in aws_sqs_queue.main_queues : q.arn],
    [for dlq in aws_sqs_queue.dlqs : dlq.arn]
  )
}

output "consume_policy_arn" {
  value = aws_iam_policy.consume_policy.arn
}

output "write_policy_arn" {
  value = aws_iam_policy.write_policy.arn
}

output "consume_role_arn" {
  value       = var.create_roles ? aws_iam_role.consume_role[0].arn : null
  description = "ARN of IAM role for consuming messages"
}

output "write_role_arn" {
  value       = var.create_roles ? aws_iam_role.write_role[0].arn : null
  description = "ARN of IAM role for sending messages"
}
