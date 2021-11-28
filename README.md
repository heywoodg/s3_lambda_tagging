# s3_lambda_tagging
Automatically tagging uploads to S3 with Lambda

This is Terraform code to create the components to automatically tag files uploaded to S3. It will create the following elements.

* A lambda function (written in Python here)
* An S3 bucket (with a Terraform generated name)
* An IAM role
* An IAM policy
* Permissions for S3 to trigger the lambda function
* An SQS queue
