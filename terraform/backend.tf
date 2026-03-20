terraform {
  required_version = ">= 1.5.0"

  # For a true production environment, uncomment and configure the S3 backend.
  # For this showcase, you may use local state or configure your specific bucket and DynamoDB table.
  
  # backend "s3" {
  #   bucket         = "my-terraform-state-bucket"
  #   key            = "gitops-nginx/terraform.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "terraform-state-lock"
  #   encrypt        = true
  # }
}
