output "bucket_name" {
  value       = awscc_s3_bucket.bucket.bucket_name
  description = "作成されたS3バケット名"
}
