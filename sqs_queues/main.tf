provider "aws" {
  region = "us-east-1"  
}

resource "aws_sqs_queue" "dlqs" {
  for_each = toset(var.queue_names)

  name = "${each.value}-dlq"
}

resource "aws_sqs_queue" "main_queues" {
  for_each = toset(var.queue_names)

  name = each.value
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlqs[each.value].arn
    maxReceiveCount     = 5
  })
}

resource "aws_iam_policy" "consume_policy" {
  name   = "sqs-consume-policy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = ["sqs:ReceiveMessage", "sqs:DeleteMessage"],
      Resource = concat(
        [for q in aws_sqs_queue.main_queues : q.arn],
        [for dlq in aws_sqs_queue.dlqs : dlq.arn]
      )
    }]
  })
}

resource "aws_iam_policy" "write_policy" {
  name   = "sqs-write-policy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = ["sqs:SendMessage"],
      Resource = [for q in aws_sqs_queue.main_queues : q.arn]
    }]
  })
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "consume_role" {
  count              = var.create_roles ? 1 : 0
  name               = "sqs-consume-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "consume_attach" {
  count      = var.create_roles ? 1 : 0
  policy_arn = aws_iam_policy.consume_policy.arn
  role       = aws_iam_role.consume_role[0].name
}

resource "aws_iam_role" "write_role" {
  count              = var.create_roles ? 1 : 0
  name               = "sqs-write-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "write_attach" {
  count      = var.create_roles ? 1 : 0
  policy_arn = aws_iam_policy.write_policy.arn
  role       = aws_iam_role.write_role[0].name
}
