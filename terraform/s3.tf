resource "aws_s3_bucket" "media_backup" {
  bucket = "ganeshc-wordpress-media-backup"

  tags = {
    Name = "${var.environment}-media-backup"
  }
}

resource "aws_s3_bucket_versioning" "media_backup" {
  bucket = aws_s3_bucket.media_backup.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "media_backup" {
  bucket                  = aws_s3_bucket.media_backup.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket" "code_backup" {
  bucket = "ganeshc-wordpress-code-backup"

  tags = {
    Name = "${var.environment}-code-backup"
  }
}

resource "aws_s3_bucket_versioning" "code_backup" {
  bucket = aws_s3_bucket.code_backup.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "code_backup" {
  bucket                  = aws_s3_bucket.code_backup.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket" "dr_backup" {
  bucket = "ganeshc-dr-backup"

  tags = {
    Name = "${var.environment}-dr-backup"
  }
}

resource "aws_s3_bucket_versioning" "dr_backup" {
  bucket = aws_s3_bucket.dr_backup.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "dr_backup" {
  bucket                  = aws_s3_bucket.dr_backup.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_cloudfront_origin_access_control" "dr" {
  name                              = "${var.environment}-dr-oac"
  description                       = "OAC for DR S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "dr" {
  enabled             = true
  comment             = "DR distribution for dr.ganeshc.shop"
  aliases             = ["dr.ganeshc.shop"]
  default_root_object = "index.html"

  origin {
    domain_name              = aws_s3_bucket.dr_backup.bucket_regional_domain_name
    origin_id                = "dr-s3-origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.dr.id
  }

  default_cache_behavior {
    target_origin_id       = "dr-s3-origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = var.acm_certificate_arn_us_east_1
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  tags = {
    Name = "${var.environment}-dr-cloudfront"
  }
}

resource "aws_s3_bucket_policy" "dr_backup" {
  bucket = aws_s3_bucket.dr_backup.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowCloudFrontOAC"
      Effect    = "Allow"
      Principal = { Service = "cloudfront.amazonaws.com" }
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.dr_backup.arn}/*"
      Condition = {
        StringEquals = {
          "AWS:SourceArn" = aws_cloudfront_distribution.dr.arn
        }
      }
    }]
  })
}
