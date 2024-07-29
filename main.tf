locals {
  inputs = { bestbuy = "bestbuy", target = "target", gamestop = "gamestop", amazon = "amazon" }
}


terraform {
  required_version = ">= 1.2.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

}

provider "aws" {
  region              = "us-east-1"
}

resource "aws_iam_role" "lambda_role" {
  name = "lambda_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = { Service = "lambda.amazonaws.com" }
      }
    ]
  })
  inline_policy {
    name = "lambda_policy"
    policy = jsonencode({
      Version = "2012-10-17",
      Statement = [
        {
          Action = [ "logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents" ],
          Effect   = "Allow",
          Resource = "*"
        }
      ]
    })
  }
}


resource "aws_lambda_function" "lambda_function" {
  function_name = "ps5_notifier"
  handler = "lambda_function.lambda_handler"
  runtime = "python3.8"
  role = aws_iam_role.lambda_role.arn
  layers = ["<INSERT_LAYER_ARN>"]
  filename = "${path.module}/lambda_function.zip"
  source_code_hash = filebase64sha256("${path.module}/lambda_function.zip")
  timeout = 60
  memory_size = 256
}

resource "aws_cloudwatch_event_rule" "event_rule" {
  name                = "ps5_notifier"
  schedule_expression = "rate(5 minutes)"
}

resource "aws_cloudwatch_event_target" "event_target" {
  for_each = local.inputs
  rule      = aws_cloudwatch_event_rule.event_rule.name
  target_id = each.key
  arn       = aws_lambda_function.lambda_function.arn
  input     = jsonencode({ key = each.value })
}

resource "sns_topic" "ps5_topic" {
  name = "ps5_topic"
}