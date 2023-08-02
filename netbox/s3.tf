resource "aws_s3_bucket" "media" {
  bucket = "somecompany-${local.resource_prefix}-media"
}

resource "aws_s3_bucket_acl" "media" {
  bucket = aws_s3_bucket.media.id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "media" {
  bucket = aws_s3_bucket.media.id
  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "media" {
  bucket = aws_s3_bucket.media.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "media" {
  bucket = aws_s3_bucket.media.id

  restrict_public_buckets = true
  ignore_public_acls      = true
  block_public_acls       = true
  block_public_policy     = true
}

data "aws_iam_policy_document" "media" {
  statement {
    sid = "AllowNetbox"

    actions = [
      "s3:GetBucketLocation",
      "s3:HeadObject",
      "s3:GetBucket",
      "s3:ListBucket",
      "s3:GetObject*",
      "s3:PutObject*",
      "s3:DeleteObject*",
      "s3:Upload*",
      "s3:*Upload",
      "s3:ListMultipartUploads",
    ]

    resources = [
      aws_s3_bucket.media.arn,
      "${aws_s3_bucket.media.arn}/*",
    ]
  }
}

resource "aws_iam_policy" "media" {
  name        = "${local.resource_prefix}-media"
  description = "Allows Netbox access to media bucket"
  policy      = data.aws_iam_policy_document.media.json
}

resource "aws_iam_role_policy_attachment" "media" {
  policy_arn = aws_iam_policy.media.arn
  role       = module.netbox_irsa.irsa.iam_role_name
}
