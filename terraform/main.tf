terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# ─── SNS Topic ────────────────────────────────────────────────
resource "aws_sns_topic" "digest" {
  name         = var.project_name
  display_name = "AI Digest"
}

# ─── IAM Role for Lambda ──────────────────────────────────────
data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda" {
  name               = "${var.project_name}-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy_document" "sns_publish" {
  statement {
    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.digest.arn]
  }
}

resource "aws_iam_role_policy" "lambda_sns" {
  name   = "${var.project_name}-sns-publish"
  role   = aws_iam_role.lambda.id
  policy = data.aws_iam_policy_document.sns_publish.json
}

# ─── Lambda Function ──────────────────────────────────────────
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/build"
  output_path = "${path.module}/lambda/package.zip"
}

resource "aws_lambda_function" "digest" {
  function_name = var.project_name
  role          = aws_iam_role.lambda.arn
  handler       = "handler.lambda_handler"
  runtime       = "python3.12"
  timeout       = 60
  memory_size   = 256

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      GEMINI_API_KEY = var.gemini_api_key
      SNS_TOPIC_ARN  = aws_sns_topic.digest.arn
      DEFAULT_PROMPT = var.default_prompt
      EMAIL_SUBJECT  = var.email_subject
      GEMINI_MODEL   = var.gemini_model
    }
  }
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${aws_lambda_function.digest.function_name}"
  retention_in_days = 7
}

# ─── EventBridge Schedule ─────────────────────────────────────
resource "aws_cloudwatch_event_rule" "daily" {
  name                = "${var.project_name}-daily"
  description         = "Trigger AI digest Lambda on schedule"
  schedule_expression = var.schedule_expression
}

resource "aws_cloudwatch_event_target" "lambda" {
  rule      = aws_cloudwatch_event_rule.daily.name
  target_id = "lambda"
  arn       = aws_lambda_function.digest.arn
}

resource "aws_lambda_permission" "eventbridge" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.digest.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily.arn
}
