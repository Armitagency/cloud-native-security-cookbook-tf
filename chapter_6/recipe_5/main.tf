resource "aws_lambda_function" "this" {
  filename      = data.archive_file.code.output_path
  function_name = var.function_name
  role          = aws_iam_role.lambda.arn
  handler       = "main.handle"

  source_code_hash = filebase64sha256(data.archive_file.code.output_path)

  runtime = "python3.9"

  depends_on = [
    data.archive_file.code
  ]
}

data "archive_file" "code" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "${path.module}/main.zip"
}

resource "aws_cloudwatch_event_rule" "daily" {
  name                = "run-daily"
  schedule_expression = "cron(* 9 ? * * *)"
}

resource "aws_cloudwatch_event_target" "daily" {
  rule = aws_cloudwatch_event_rule.daily.name
  arn  = aws_lambda_function.this.arn
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily.arn
}

resource "aws_iam_role" "lambda" {
  name               = var.function_name
  assume_role_policy = data.aws_iam_policy_document.assume.json
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
  ]
}

data "aws_iam_policy_document" "assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = [
        "lambda.amazonaws.com"
      ]
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "foobar" {
  alarm_actions = [
    aws_sns_topic.alarm.arn
  ]
  alarm_name                = "${var.function_name}-failures"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "1"
  insufficient_data_actions = []
  metric_name               = "Errors"
  namespace                 = "AWS/Lambda"
  period                    = "60"
  statistic                 = "Sum"
  threshold                 = "1"
  treat_missing_data        = "notBreaching"
}

resource "aws_sns_topic" "alarm" {
  name = "${var.function_name}-failures"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alarm.arn
  protocol  = "email"
  endpoint  = var.email
}
