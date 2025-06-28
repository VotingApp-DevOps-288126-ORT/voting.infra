
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = path.module
  output_path = "${path.module}/lambda.zip"
}

data "aws_iam_role" "lab_role" {
  name = "LabRole"
}

resource "aws_lambda_function" "eks_backup_lambda" {
  function_name    = "counter-ecr-images-by-apps"
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = filebase64sha256(data.archive_file.lambda_zip.output_path)
  role             = data.aws_iam_role.lab_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.11"
  timeout          = 900

  environment {
    variables = {
      REGION      = var.region
      REPO_VOTE   = var.ecr_vote
      REPO_RESULT = var.ecr_result
      REPO_WORKER = var.ecr_worker
    }
  }
}
