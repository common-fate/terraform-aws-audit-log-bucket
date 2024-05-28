variable "bucket_name" {
  description = "value"
}

variable "writer_role_name_prefix" {
  description = "name_prefix for the writer role. Defaults to 'common-fate-audit-log-s3-write-role-'. If setting 'write_role_name', set this to an empty string."
  default     = "common-fate-audit-log-s3-write-role-"
}

variable "writer_role_name" {
  description = "name for the writer role. If specifying this, set 'writer_role_name_prefix' this to an empty string."
  default     = null
  nullable    = true
}

variable "writer_policy_name_prefix" {
  description = "name_prefix for the writer role. Defaults to 'common-fate-audit-logs-write-'. If setting 'write_policy_name', set this to an empty string."
  default     = "common-fate-audit-log-s3-write-role-"
}

variable "writer_policy_name" {
  description = "name for the writer policy. If specifying this, set 'writer_policy_name_prefix' this to an empty string."
  default     = null
  nullable    = true
}

variable "common_fate_aws_account" {
  description = "The AWS account that Common Fate is deployed to."
}

variable "assume_role_external_id" {
  description = "The external ID to be used for the IAM policy trust relation"
  type        = string
  default     = ""
}

variable "lifecycle_rules" {
  type = object({
    prefix = string

    noncurrent_version_transition = list(object({
      days          = string
      storage_class = string
    }))

    transition = list(object({
      days          = string
      storage_class = string
    }))

    noncurrent_version_expiration = object({
      days = string
    })

    expiration = object({
      days = string
    })
  })

  description = "Object representing the lifecycle rules of the bucket"
  default     = null
}


variable "bucket_logging_target" {
  type        = map(string)
  description = "Map of S3 bucket access logging target properties"
  default     = {}

  # Expected value:
  # {
  #   bucket = "my_bucket"
  #   prefix = "custom_prefix" // optional, defaults to name of bucket
  # }
}

variable "versioning" {
  type        = bool
  description = "Toggle for versioning the bucket. Defaults to true"
  default     = true
}

variable "object_ownership" {
  type        = string
  description = "Ownership of objects written to the bucket"
  default     = "BucketOwnerEnforced"
}

variable "force_destroy" {
  type        = bool
  description = "Boolean to toggle force destroy of bucket. Defaults to true; should be changed in exceptional circumstances"
  default     = true
}
