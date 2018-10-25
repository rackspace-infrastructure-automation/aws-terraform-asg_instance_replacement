data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/lambda.zip"
}

resource "aws_iam_role" "lambda" {
  name               = "${var.name}"
  assume_role_policy = "${data.aws_iam_policy_document.assume_role.json}"
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
  policy = "${data.aws_iam_policy_document.logs.json}"
}

resource "aws_iam_policy" "lambda" {
  name   = "${var.name}-lambda"
  policy = "${data.aws_iam_policy_document.lambda.json}"
}

resource "aws_iam_policy_attachment" "logs" {
  name       = "${var.name}-logs"
  roles      = ["${aws_iam_role.lambda.name}"]
  policy_arn = "${aws_iam_policy.logs.arn}"
}

resource "aws_iam_policy_attachment" "lambda" {
  name       = "${var.name}-lambda"
  roles      = ["${aws_iam_role.lambda.name}"]
  policy_arn = "${aws_iam_policy.lambda.arn}"
}

resource "aws_lambda_function" "lambda" {
  function_name                  = "${var.name}"
  description                    = "Manages ASG instance replacement"
  filename                       = "${data.archive_file.lambda.output_path}"
  handler                        = "main.lambda_handler"
  memory_size                    = 128
  reserved_concurrent_executions = 0
  role                           = "${aws_iam_role.lambda.arn}"
  runtime                        = "python3.6"
  source_code_hash               = "${base64sha256(file(data.archive_file.lambda.output_path))}"
  timeout                        = "${var.timeout}"
}

data "aws_iam_policy_document" "lambda" {
  statement {
    effect = "Allow"

    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:ResumeProcesses",
      "autoscaling:SetInstanceHealth",
      "autoscaling:SuspendProcesses",
      "autoscaling:UpdateAutoScalingGroup",
      "ec2:TerminateInstances",
      "elasticloadbalancing:DescribeInstanceHealth",
      "elasticloadbalancing:DescribeTargetHealth",
    ]

    resources = [
      "*",
    ]
  }
}
