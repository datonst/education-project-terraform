resource "aws_cognito_user_pool" "this" {
  name = "${var.prefix}-user-pool"

  # Password policy
  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
    require_uppercase = true
  }
  # Multi-factor authentication (MFA)
  # mfa_configuration = "OPTIONAL"
  user_pool_tier = "ESSENTIALS"
  # Email settings
  auto_verified_attributes = ["email"]

  # Schema attributes
  schema {
    name                = "email"
    attribute_data_type = "String"
    mutable             = true
    required            = true
  }

  # Advanced security mode
  # user_pool_add_ons {
  #   advanced_security_mode = "ENFORCED"
  # }

  # Prevent modification of schema which causes errors
  lifecycle {
    ignore_changes = [
      schema
    ]
  }

  tags = var.tags
}

resource "aws_cognito_user_pool_client" "this" {
  name                                 = "${var.prefix}-app-client"
  user_pool_id                         = aws_cognito_user_pool.this.id
  generate_secret                      = false
  refresh_token_validity               = 30
  access_token_validity                = 1
  id_token_validity                    = 1
  allowed_oauth_flows                  = ["code", "implicit"]
  allowed_oauth_scopes                 = ["phone", "email", "openid", "profile", "aws.cognito.signin.user.admin"]
  allowed_oauth_flows_user_pool_client = true
  callback_urls                        = var.callback_urls
  logout_urls                          = var.logout_urls
  supported_identity_providers         = ["COGNITO"]

  # JWT token configuration
  token_validity_units {
    access_token  = "hours"
    id_token      = "hours"
    refresh_token = "days"
  }
}

# Domain for hosted UI
resource "aws_cognito_user_pool_domain" "this" {
  domain       = var.domain_prefix
  user_pool_id = aws_cognito_user_pool.this.id
}

data "aws_region" "current" {}
