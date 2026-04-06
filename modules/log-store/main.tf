data "aws_caller_identity" "current" {}

resource "awscc_s3_bucket" "log_store" {
  bucket_encryption = {
    server_side_encryption_configuration = [
      { server_side_encryption_by_default = { sse_algorithm = "AES256" } },
    ]
  }
  bucket_name = "${var.project}-${var.environment}-logs"
  lifecycle_configuration = {
    rules = [
      {
        abort_incomplete_multipart_upload = { days_after_initiation = 1 }
        status                            = "Enabled"
      },
    ]
  }
  public_access_block_configuration = {
    block_public_acls       = true
    block_public_policy     = true
    ignore_public_acls      = true
    restrict_public_buckets = true
  }
  tags                     = var.tags
  versioning_configuration = { status = "Enabled" }

  lifecycle {
    ignore_changes  = [tags, ] # NOTE: タグの順番で差分を検知するため無視させる
    prevent_destroy = true
  }
}

resource "awscc_s3_bucket_policy" "log_store" {
  bucket = awscc_s3_bucket.log_store.bucket_name
  policy_document = jsonencode({
    "Version" = "2012-10-17"
    "Statement" = [
      {
        "Effect"    = "Allow"
        "Principal" = { "Service" = "logging.s3.amazonaws.com" }
        "Action"    = "s3:PutObject"
        "Resource"  = "${awscc_s3_bucket.log_store.arn}/s3/*"
        "Condition" = {
          "StringEquals" = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      },
    ]
  })
}
