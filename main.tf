resource "aws_s3_bucket" "this" {
  bucket        = var.bucket_name
  force_destroy = var.force_destroy


  tags = {
    "common-fate-terraform-module" = "https://github.com/common-fate/terraform-aws-audit-log-bucket"
  }
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id
  versioning_configuration {
    status = var.versioning_status
  }
}

resource "aws_s3_bucket_logging" "this" {
  count  = contains(keys(var.bucket_logging_target), "bucket") ? 1 : 0
  bucket = aws_s3_bucket.this.id

  # Enable S3 Bucket Logging to the logs bucket
  target_bucket = var.bucket_logging_target["bucket"]
  target_prefix = lookup(var.bucket_logging_target, "prefix", "${var.bucket_name}/")
}

resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    object_ownership = var.object_ownership
  }
}


resource "aws_iam_role" "write" {
  name = var.writer_role_name

  tags = {
    "common-fate-allow-assume-role" = "true",
    "common-fate-terraform-module"  = "https://github.com/common-fate/terraform-aws-audit-log-bucket"
  }

  assume_role_policy = data.aws_iam_policy_document.assume_roles_policy.json
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

data "aws_iam_policy_document" "assume_roles_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "AWS"
      identifiers = [var.common_fate_aws_account]
    }

    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values   = [var.assume_role_external_id]
    }
  }
}

resource "aws_iam_policy" "write" {
  name        = var.writer_policy_name
  name_prefix = var.writer_policy_name_prefix
  description = "Allows writing to the audit logs bucket"

  tags = {
    "common-fate-terraform-module" = "https://github.com/common-fate/terraform-aws-audit-log-bucket"
  }

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "VerifyBucketExists",
        "Effect" : "Allow",
        "Action" : [
          "s3:GetBucketLocation",
        ],
        "Resource" : aws_s3_bucket.this.arn
      },
      {
        "Sid" : "Write",
        "Effect" : "Allow",
        "Action" : [
          "s3:PutObject"
        ],
        "Resource" : "${aws_s3_bucket.this.arn}/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "audit_log_bucket_write_attach" {
  role       = aws_iam_role.write.name
  policy_arn = aws_iam_policy.write.arn
}

resource "aws_s3_bucket_lifecycle_configuration" "main" {
  count  = var.lifecycle_rules != null ? 1 : 0
  bucket = aws_s3_bucket.this.id

  rule {
    id = "common-fate-audit-logs-lifecycle"

    filter {
      prefix = var.lifecycle_rules.prefix
    }

    status = "Enabled"

    dynamic "noncurrent_version_transition" {
      for_each = var.lifecycle_rules.noncurrent_version_transition

      content {
        noncurrent_days = noncurrent_version_transition.value.days
        storage_class   = noncurrent_version_transition.value.storage_class
      }
    }

    dynamic "transition" {
      for_each = var.lifecycle_rules.transition

      content {
        days          = transition.value.days
        storage_class = transition.value.storage_class
      }
    }

    dynamic "noncurrent_version_expiration" {
      for_each = var.lifecycle_rules.noncurrent_version_expiration.days == "-1" ? [] : [var.lifecycle_rules.noncurrent_version_expiration.days]

      content {
        noncurrent_days = noncurrent_version_expiration.value
      }
    }

    dynamic "expiration" {
      for_each = var.lifecycle_rules.expiration.days == "-1" ? [] : [var.lifecycle_rules.expiration.days]

      content {
        days = expiration.value
      }
    }
  }
}
