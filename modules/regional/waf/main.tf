locals {
  scope = {
    "CLOUDFRONT" = "CLOUDFRONT"
    "REGIONAL"   = "REGIONAL"
  }
  ip_address_version = {
    "IPV6" = "IPV6"
    "IPV4" = "IPV4"
  }
  listRulesAWSManaged = [
    {
      priority = 1,
      name     = "AWSManagedRulesAmazonIpReputationList"
    },
    {
      priority = 2,
      name     = "AWSManagedRulesCommonRuleSet"
    },
    {
      priority = 3,
      name     = "AWSManagedRulesKnownBadInputsRuleSet",
    },
    {
      priority = 4,
      name     = "AWSManagedRulesSQLiRuleSet"
    },

  ]
}

resource "aws_wafv2_web_acl" "this" {
  name  = var.waf_names
  scope = local.scope.CLOUDFRONT

  default_action {
    allow {}
  }
  rule {
    name     = "AWS-RateBasedRule-IP-300-CreatedByCloudFront"
    priority = 0
    action {
      count {}
    }
    statement {
      rate_based_statement {
        limit              = 300
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "friendly-rule-metric-name"
      sampled_requests_enabled   = false
    }
  }
  dynamic "rule" {
    for_each = { for rule in local.listRulesAWSManaged : rule.priority => rule }
    content {
      name     = "AWS-${rule.value.name}"
      priority = rule.value.priority

      override_action {
        count {}
      }

      statement {
        managed_rule_group_statement {
          name        = rule.value.name
          vendor_name = "AWS"
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = false
        metric_name                = "friendly-rule-metric-name"
        sampled_requests_enabled   = false
      }
    }

  }
  visibility_config {
    cloudwatch_metrics_enabled = false
    metric_name                = "friendly-metric-name"
    sampled_requests_enabled   = false
  }
}
