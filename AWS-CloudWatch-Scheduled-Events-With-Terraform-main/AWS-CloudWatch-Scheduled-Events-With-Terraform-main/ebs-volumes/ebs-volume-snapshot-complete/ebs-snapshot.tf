resource "null_resource" "build_lambda_zip" {

  triggers = {
    key = uuid()
  }

  provisioner "local-exec" {
    working_dir = "."

    command = <<EOF
    mkdir ${path.module}/lambda
    mkdir ${path.module}/tmp
    cp    ${path.module}/create_snapshot.py ${path.module}/tmp/create_snapshot.py
EOF
  }
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/tmp"
  output_path = "${path.module}/lambda/tmp.zip"

  depends_on = [
    null_resource.build_lambda_zip
  ]
}

data "aws_iam_policy_document" "create_ebs_volume_snapshot_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}



resource "aws_iam_role" "create_ebs_volume_snapshot" {
  name               = "create-ebs-volume-snapshot"
  assume_role_policy = data.aws_iam_policy_document.create_ebs_volume_snapshot_assume_role_policy.json
}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "create_ebs_volume_snapshot" {
  statement {
    effect = "Allow"

    sid = "CreateEBSVolumeSnapshot"

    actions = [
      "ec2:*",
    ]

    resources = [
      "*",
    ]
  }
}

resource "aws_iam_role_policy" "create_ebs_volume_iam_role_policy_lambda" {
  name   = "create_ebs_volume"
  role   = aws_iam_role.create_ebs_volume_snapshot.id
  policy = data.aws_iam_policy_document.create_ebs_volume_snapshot.json
}

resource "aws_lambda_function" "create_ebs_volume_snapshot" {
  function_name    = "create-ebs-volume-snapshot"
  filename         = "${path.module}/lambda/tmp.zip"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  role             = aws_iam_role.create_ebs_volume_snapshot.arn
  runtime          = "python3.6"
  handler          = "create_snapshot.lambda_handler"
  timeout          = "60"
  publish          = true

  depends_on = [
    data.archive_file.lambda_zip
  ]

  environment {
    variables = {
      VOLUME_ID = tolist(aws_instance.this.ebs_block_device)[0]["volume_id"]
    }
  }

  tags = {
    Terraform = true
  }
}

resource "aws_cloudwatch_event_rule" "ebs_snapshot" {
  name                = "ebs-snapshot"
  description         = "Cronlike scheduled for creating daily ebs volume snapshot."
  schedule_expression = var.cron_expression
}

resource "aws_cloudwatch_event_target" "ebs_backup" {
  rule      = aws_cloudwatch_event_rule.ebs_snapshot.name
  target_id = aws_lambda_function.create_ebs_volume_snapshot.id
  arn       = aws_lambda_function.create_ebs_volume_snapshot.arn
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatchCreateEBSVolumeSnapshot"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.create_ebs_volume_snapshot.arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ebs_snapshot.arn
}




