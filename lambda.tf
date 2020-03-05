data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      identifiers = ["lambda.amazonaws.com"]
      type        = "Service"
    }
  }
}

data "archive_file" "lambda" {
  output_path = "${path.module}/lambda.zip"
  source_dir  = "${path.module}/lambda"
  type        = "zip"
}

resource "aws_iam_role" "lambda" {
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  name               = var.name
}

# Attach a policy for logs.

data "aws_iam_policy_document" "logs" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.name}:*",
    ]
  }
}

resource "aws_iam_policy" "logs" {
  name   = "${var.name}-logs"
  policy = data.aws_iam_policy_document.logs.json
}

resource "aws_iam_policy" "lambda" {
  name   = "${var.name}-lambda"
  policy = data.aws_iam_policy_document.lambda.json
}

resource "aws_iam_policy_attachment" "logs" {
  name       = "${var.name}-logs"
  policy_arn = aws_iam_policy.logs.arn
  roles      = [aws_iam_role.lambda.name]
}

resource "aws_iam_policy_attachment" "lambda" {
  name       = "${var.name}-lambda"
  policy_arn = aws_iam_policy.lambda.arn
  roles      = [aws_iam_role.lambda.name]
}

resource "aws_lambda_function" "lambda" {
  description                    = "Manages ASG instance replacement"
  filename                       = data.archive_file.lambda.output_path
  function_name                  = var.name
  handler                        = "main.lambda_handler"
  memory_size                    = 128
  reserved_concurrent_executions = -1
  role                           = aws_iam_role.lambda.arn
  runtime                        = "python3.8"
  source_code_hash               = filebase64sha256(data.archive_file.lambda.output_path)
  timeout                        = var.timeout
}

data "aws_iam_policy_document" "lambda" {
  statement {
    effect    = "Deny"
    resources = ["*"]

    actions = [
      "autoscaling:ResumeProcesses",
      "autoscaling:SetInstanceHealth",
      "autoscaling:SuspendProcesses",
      "autoscaling:UpdateAutoScalingGroup",
    ]

    condition {
      test     = "StringEqualsIgnoreCase"
      variable = "autoscaling:ResourceTag/InstanceReplacement"

      values = [
        "0",
        "disabled",
        "false",
        "no",
        "off",
      ]
    }
  }

  statement {
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "autoscaling:ResumeProcesses",
      "autoscaling:SetInstanceHealth",
      "autoscaling:SuspendProcesses",
      "autoscaling:UpdateAutoScalingGroup",
    ]

    condition {
      test     = "StringLike"
      variable = "autoscaling:ResourceTag/InstanceReplacement"
      values   = ["*"]
    }
  }

  statement {
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "elasticloadbalancing:DescribeInstanceHealth",
      "elasticloadbalancing:DescribeTargetHealth",
    ]
  }
}

