resource "aws_iam_role" "lambda_edge_role" {
  name = "${var.prefix}-lambda-edge-auth-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = [
            "lambda.amazonaws.com",
            "edgelambda.amazonaws.com"
          ]
        }
        Effect = "Allow"
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "lambda_edge_policy" {
  name = "${var.prefix}-lambda-edge-auth-policy"
  role = aws_iam_role.lambda_edge_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
        Effect   = "Allow"
      },
      {
        Action = [
          "cognito-idp:GetUser",
          "cognito-idp:AdminGetUser"
        ]
        Resource = var.cognito_user_pool_arn
        Effect   = "Allow"
      },
      {
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion"
        ]
        Resource = "${var.s3_bucket_arn}/*"
        Effect   = "Allow"
      },
      {
        Action = [
          "s3:PutObject"
        ]
        Resource = [
          "${var.s3_bucket_arn}/*"
        ]
        Effect = "Allow"
      },
      {
        Action = [
          "s3:ListBucket"
        ]
        Resource = var.s3_bucket_arn
        Effect   = "Allow"
      }
    ]
  })
}

# Create a directory for Lambda code and dependencies
resource "null_resource" "lambda_dependencies" {
  triggers = {
    # Only rebuild when Lambda code changes
    source_code_hash = sha256("${path.module}/lambda_code/index.js")
  }

  provisioner "local-exec" {
    command     = <<EOT
      # Debug - print current directory and module path
      echo "Current directory: $(pwd)"
      echo "Module path: ${path.module}"
      
      # Create temp directories with absolute paths
      LAMBDA_BUILD="$(pwd)/${path.module}/lambda_build"
      LAMBDA_CODE="$(pwd)/${path.module}/lambda_code"
      
      echo "Creating directories: $LAMBDA_BUILD and $LAMBDA_CODE"
      mkdir -p "$LAMBDA_BUILD"
      mkdir -p "$LAMBDA_CODE"
      
      # Create package.json with absolute path
      echo "Creating package.json in $LAMBDA_BUILD"
      cat > "$LAMBDA_BUILD/package.json" <<EOF
{
  "name": "auth-lambda",
  "version": "1.0.0",
  "description": "Lambda@Edge authentication function",
  "main": "index.js",
  "dependencies": {
    "jsonwebtoken": "^9.0.0",
    "jwks-rsa": "^3.0.1"
  }
}
EOF
      
      # Skip creating index.js, assuming it already exists in lambda_code directory
      echo "Using existing index.js from lambda_code directory"

      # Copy index.js to build directory
      echo "Copying index.js to build directory"
      cp "$LAMBDA_CODE/index.js" "$LAMBDA_BUILD/index.js"
      
      # Install dependencies and create zip file
      echo "Installing dependencies in $LAMBDA_BUILD"
      cd "$LAMBDA_BUILD" && npm install --production
      
      echo "Creating zip file"
      # Create a direct absolute path for the zip file, not relative to the build directory
      ZIP_FILE="../auth_lambda.zip"
      # Ensure parent directory exists
      mkdir -p "$(dirname "$ZIP_FILE")"
      echo "ZIP file will be created at: $ZIP_FILE"
      
      # Create the zip file in the correct location
      cd "$LAMBDA_BUILD" && zip -r "$ZIP_FILE" index.js node_modules || echo "Zip creation failed with code $?"
      
      # Verify zip file was created
      ls -la "$ZIP_FILE" || echo "Failed to create zip file"
    EOT
    interpreter = ["bash", "-c"]
  }
}

# Auth Lambda function
resource "aws_lambda_function" "auth_lambda" {
  provider         = aws.us_east_1 # Lambda@Edge must be deployed in us-east-1
  function_name    = "${var.prefix}-auth-lambda"
  filename         = "${path.module}/auth_lambda.zip"
  source_code_hash = filebase64sha256("${path.module}/auth_lambda.zip")
  role             = aws_iam_role.lambda_edge_role.arn
  handler          = "index.handler"
  runtime          = "nodejs18.x"
  publish          = true # Required for Lambda@Edge
  timeout          = 5
  memory_size      = 128

  depends_on = [null_resource.lambda_dependencies]

  tags = var.tags

  lifecycle {
    create_before_destroy = true
    ignore_changes        = all
  }
}

