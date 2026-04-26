output "state_store_bucket_name" {
  description = ""
  value       = awscc_s3_bucket.state_store.bucket_name
}

output "read_policy_size" {
  description = ""
  value       = length(data.aws_iam_policy_document.read.json)
}

output "write_policy_size" {
  description = ""
  value       = length(data.aws_iam_policy_document.write.json)
}
