resource "awscc_s3_bucket" "bucket" {
  bucket_encryption = {
    server_side_encryption_configuration = [
      { server_side_encryption_by_default = { sse_algorithm = "AES256" } },
    ]
  }
  bucket_name = "${var.project}-${var.environment}-state-backend"
  lifecycle_configuration = {
    rules = [
      {
        abort_incomplete_multipart_upload = { days_after_initiation = 1 }
        status                            = "Enabled"
      },
    ]
  }
  #logging_configuration = {} # TODO: 将来的に設定を検討する。
  public_access_block_configuration = {
    block_public_acls       = true
    block_public_policy     = true
    ignore_public_acls      = true
    restrict_public_buckets = true
  }
  tags = [
    { key = "Environment", value = var.environment },
    { key = "Project", value = var.project },
    { key = "Terragrunt", value = var.terragrunt_path },
  ]
  versioning_configuration = { status = "Enabled" }

  lifecycle {
    ignore_changes  = [tags] # NOTE: タグの順番で差分を検知するため無視させる
    prevent_destroy = true
  }
}
