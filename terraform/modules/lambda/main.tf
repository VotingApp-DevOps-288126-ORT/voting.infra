data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = path.module
  output_path = "${path.module}/lambda.zip"
}

data "aws_iam_role" "lab_role" {
  name = "LabRole"
}

resource "aws_lambda_function" "eks_backup_lambda" {
  function_name    = "eks-backup-lambda"
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = filebase64sha256(data.archive_file.lambda_zip.output_path)
  role             = data.aws_iam_role.lab_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.11"
  timeout          = 900

  environment {
    variables = {
      REGION           = "us-east-1"
      CLUSTER_NAME     = "cluster-eks-prod"
      BUCKET_NAME      = "voting.backend"
      ENV              = "prod"
      CLUSTER_ENDPOINT = var.cluster_endpoint
      CLUSTER_CA       = var.cluster_ca
      EKS_TOKEN        = var.cluster_token
    }
  }
}
