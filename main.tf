resource "random_id" "id" {
  byte_length = 8
}

data "archive_file" "default" {
  type        = "zip"
  source_dir  = "${path.module}/files/"
  output_path = "${path.module}/myzip/python.zip"
}


# Create the lambda function
resource "aws_lambda_function" "s3lambda" {
  filename      = "${path.module}/myzip/python.zip"
  #function_name = "s3lambdafunction"
  function_name = "${random_id.id.hex}-${var.lambda_function_name}"
  role          = aws_iam_role.s3_lambda_role.arn
  handler       = "index.lambda_handler"
  runtime       = "python3.8"
  depends_on    = [aws_iam_role_policy_attachment.logging_policy_attach]
}


resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3lambda.arn
  principal     = "s3.amazonaws.com"
  #This arn should be the arn of the S3 bucket
  #source_arn = "arn:aws:s3:::mybucketname"
  source_arn = aws_s3_bucket.bucket.arn
}

resource "aws_s3_bucket" "bucket" {
  #bucket = "mybucketname"
  #lifecycle {
  #  prevent_destroy = true
  #}
}

# Create the IAM service role for the lambda function
resource "aws_iam_role" "s3_lambda_role" {
  name               = "s3_lambda_function_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

# IAM policy for logging from a lambda

resource "aws_iam_policy" "lambda_logging" {
  name        = "LambdaLoggingPolicy"
  path        = "/"
  description = "IAM policy for logging from a lambda"
  policy      = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "arn:aws:logs:*:*:*",
            "Effect": "Allow"
        },
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": "s3:PutObjectTagging",
            "Resource": "arn:aws:s3:::*/*"
        },
        {
            "Action": [
                "sqs:ReceiveMessage",
                "sqs:DeleteMessage",
                "sqs:GetQueueAttributes",
                "sqs:SendMessage",
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "arn:aws:sqs:*",
            "Effect": "Allow"
        }
    ]
}
EOF    
}

# Attaching the policy to the role

resource "aws_iam_role_policy_attachment" "logging_policy_attach" {
  role       = aws_iam_role.s3_lambda_role.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}



resource "aws_s3_bucket_notification" "s3_bucket_notification" {
  bucket = aws_s3_bucket.bucket.id
  lambda_function {
    lambda_function_arn = aws_lambda_function.s3lambda.arn
    events              = ["s3:ObjectCreated:*"]
    #filter_prefix       = "AWSLogs/"
    #filter_suffix       = ".log"
  }
  depends_on = [
    aws_iam_role_policy_attachment.logging_policy_attach,
    aws_lambda_permission.allow_bucket,
    aws_lambda_function.s3lambda
  ]
}


resource "aws_sqs_queue" "sqs_queue" {
  name = "${random_id.id.hex}-lambda-s3-tag"
}

resource "aws_lambda_function_event_invoke_config" "invokesuccess" {
  function_name = aws_lambda_function.s3lambda.function_name
  destination_config {
    on_success {
      destination = aws_sqs_queue.sqs_queue.arn
    }
  }
}