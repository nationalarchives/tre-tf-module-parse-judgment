resource "aws_iam_role" "parse_judgment" {
  name               = "${var.env}-${var.prefix}-parse-judgment-role"
  assume_role_policy = data.aws_iam_policy_document.parse_judgment_assume_role_policy.json
  permissions_boundary = var.tre_permission_boundary_arn
  inline_policy {
    name   = "parse-judgment-policies"
    policy = data.aws_iam_policy_document.parse_judgment_machine_policy.json
  }
}

data "aws_iam_policy_document" "parse_judgment_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["states.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "parse_judgment_machine_policy" {
  statement {
    actions = [
      "logs:CreateLogDelivery",
      "logs:GetLogDelivery",
      "logs:UpdateLogDelivery",
      "logs:DeleteLogDelivery",
      "logs:ListLogDeliveries",
      "logs:PutResourcePolicy",
      "logs:DescribeResourcePolicies",
      "logs:DescribeLogGroups"
    ]

    effect    = "Allow"
    resources = ["*"]
  }

  statement {
    actions = [
      "xray:PutTraceSegments",
      "xray:PutTelemetryRecords",
      "xray:GetSamplingRules",
      "xray:GetSamplingTargets"
    ]

    effect    = "Allow"
    resources = ["*"]
  }

  statement {
    sid     = "InvokeLambdaPolicy"
    effect  = "Allow"
    actions = ["lambda:InvokeFunction"]
    resources = [
      aws_lambda_function.parse_judgment.arn
    ]
  }
}

# Lambda Roles

# Role for the lambda functions in parse_judgment step-function
resource "aws_iam_role" "parse_judgment_lambda_role" {
  name               = "${var.env}-${var.prefix}-parse-judgment-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy.json
  permissions_boundary = var.tre_permission_boundary_arn
}

resource "aws_iam_role_policy_attachment" "parse_judgment_lambda_logs" {
  role       = aws_iam_role.parse_judgment_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSOpsWorksCloudWatchLogs"
}

# Role for the parse-judgment step-function trigger
resource "aws_iam_role" "parse_judgment_trigger" {
  name               = "${var.env}-${var.prefix}-parse-judgment-trigger-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy.json
  permissions_boundary = var.tre_permission_boundary_arn
  inline_policy {
    name   = "${var.env}-${var.prefix}-parse-judgment-trigger"
    policy = data.aws_iam_policy_document.parse_judgment_trigger.json
  }
}

resource "aws_iam_role_policy_attachment" "parse_judgment_sqs_lambda_trigger" {
  role       = aws_iam_role.parse_judgment_trigger.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole"
}

# Lambda policy documents

data "aws_iam_policy_document" "lambda_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "parse_judgment_trigger" {
  statement {
    actions   = ["states:StartExecution"]
    effect    = "Allow"
    resources = [aws_sfn_state_machine.parse_judgment.arn]
  }
}

# SQS Polciy

data "aws_iam_policy_document" "tre_parse_judgment_in_queue" {
  statement {
    actions = ["sqs:SendMessage"]
    effect  = "Allow"
    principals {
      type = "Service"
      identifiers = [
        "sns.amazonaws.com"
      ]
    }
    resources = [
      aws_sqs_queue.tre_parse_judgment_in.arn
    ]
  }
}
