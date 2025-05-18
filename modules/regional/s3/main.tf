resource "aws_s3_bucket" "main" {
  bucket = var.bucket

  tags = var.tags
}

resource "aws_s3_bucket_public_access_block" "access_good_1" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = var.block_public_acls
  block_public_policy     = var.block_public_policy
  ignore_public_acls      = var.ignore_public_acls
  restrict_public_buckets = var.restrict_public_buckets
}

resource "aws_s3_bucket_versioning" "example" {
  bucket = aws_s3_bucket.main.id

  versioning_configuration {
    status = var.enable_versioning
  }
}
