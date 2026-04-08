output "arn" {
  value       = awscc_s3_bucket.log_store.arn
  description = ""
}

output "bucket_name" {
  value       = awscc_s3_bucket.log_store.bucket_name
  description = ""
}
