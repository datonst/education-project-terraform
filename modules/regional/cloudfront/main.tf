resource "aws_cloudfront_origin_access_identity" "default" {
  comment = "OAI for S3 origin"
}

resource "aws_cloudfront_distribution" "this" {
  enabled     = true
  aliases     = var.domain_names
  price_class = "PriceClass_All"
  web_acl_id  = var.web_acl_id
  tags        = var.tags

  # ALB Origin
  origin {
    domain_name = var.regional_domain_name
    origin_id   = "${var.origin_id}-alb"
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  # S3 Origin
  origin {
    domain_name = var.s3_bucket_domain_name
    origin_id   = "${var.origin_id}-s3"
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.default.cloudfront_access_identity_path
    }
  }

  # Default cache behavior - routes to ALB
  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "${var.origin_id}-alb"
    forwarded_values {
      query_string = true
      headers      = ["Origin", "Authorization", "Host"]

      cookies {
        forward = "all"
      }
    }

    viewer_protocol_policy = "redirect-to-https" # Chuyển từ allow-all sang redirect-to-https để tăng bảo mật
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  # # S3 behavior for images
  # ordered_cache_behavior {
  #   path_pattern     = "/images/*"
  #   allowed_methods  = ["GET", "HEAD", "OPTIONS"]
  #   cached_methods   = ["GET", "HEAD", "OPTIONS"]
  #   target_origin_id = "${var.origin_id}-s3"

  #   forwarded_values {
  #     query_string = false

  #     cookies {
  #       forward = "none"
  #     }
  #   }

  #   min_ttl                = 0
  #   default_ttl            = 0
  #   max_ttl                = 0
  #   compress               = true
  #   viewer_protocol_policy = "redirect-to-https"

  #   # Lambda@Edge xác thực truy cập cho endpoint /images/*
  #   lambda_function_association {
  #     event_type   = "viewer-request"
  #     lambda_arn   = var.auth_lambda_arn
  #     include_body = false
  #   }
  # }

  # # S3 behavior for videos
  # ordered_cache_behavior {
  #   path_pattern     = "/videos/*"
  #   allowed_methods  = ["GET", "HEAD", "OPTIONS"]
  #   cached_methods   = ["GET", "HEAD", "OPTIONS"]
  #   target_origin_id = "${var.origin_id}-s3"

  #   forwarded_values {
  #     query_string = false

  #     cookies {
  #       forward = "none"
  #     }
  #   }

  #   min_ttl                = 0
  #   default_ttl            = 0
  #   max_ttl                = 0
  #   compress               = false
  #   viewer_protocol_policy = "redirect-to-https"

  #   # Lambda@Edge xác thực truy cập cho endpoint /videos/*
  #   lambda_function_association {
  #     event_type   = "viewer-request"
  #     lambda_arn   = var.auth_lambda_arn
  #     include_body = false
  #   }
  # }

  # S3 behavior for static files
  ordered_cache_behavior {
    path_pattern     = "/static/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = "${var.origin_id}-s3"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  # Unified behavior for private files (both upload and access)
  ordered_cache_behavior {
    path_pattern     = "/private/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "${var.origin_id}-s3"

    forwarded_values {
      query_string = true
      headers      = ["Origin", "Authorization", "Content-Type", "x-user-id"]

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0
    compress               = true
    viewer_protocol_policy = "https-only"

    # Lambda@Edge cho API upload và kiểm tra quyền
    lambda_function_association {
      event_type   = "viewer-request"
      lambda_arn   = var.auth_lambda_arn
      include_body = true
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = var.cloudfront_default_certificate
    acm_certificate_arn            = var.acm_certificate_arn
    ssl_support_method             = var.ssl_support_method
    minimum_protocol_version       = "TLSv1.2_2019"
  }

  dynamic "custom_error_response" {
    for_each = { for item in var.custom_error_response : item.error_code => item }
    content {
      error_caching_min_ttl = custom_error_response.value.error_caching_min_ttl
      error_code            = custom_error_response.value.error_code
      response_code         = custom_error_response.value.response_code
      response_page_path    = custom_error_response.value.response_page_path
    }
  }
}

data "aws_iam_policy_document" "s3_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${var.s3_bucket_arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.default.iam_arn]
    }
  }

  # Thêm statement cho phép PUT/POST thông qua CloudFront OAI
  statement {
    actions   = ["s3:PutObject"]
    resources = ["${var.s3_bucket_arn}/private/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.default.iam_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "this" {
  bucket = var.s3_bucket_id
  policy = data.aws_iam_policy_document.s3_policy.json
}



