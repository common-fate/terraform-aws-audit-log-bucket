output "bucket_name" {
  description = "The name of the created S3 bucket."
  value       = aws_s3_bucket.this.bucket
}

output "bucket_arn" {
  description = "The ARN of the created S3 bucket."
  value       = aws_s3_bucket.this.arn
}

output "write_role_arn" {
  description = "The ARN of the role created with permission to write to the S3 bucket."
  value       = aws_iam_role.write.arn
}
