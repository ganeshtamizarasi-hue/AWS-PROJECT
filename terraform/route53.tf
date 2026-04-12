# ── Data source: existing hosted zone ────────────────────────
data "aws_route53_zone" "main" {
  name         = "ganeshc.shop"
  private_zone = false
}

# ── A Record: ganeshc.shop → ALB ─────────────────────────────
resource "aws_route53_record" "root" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "ganeshc.shop"
  type    = "A"

  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}

# ── A Record: www.ganeshc.shop → ALB ─────────────────────────
resource "aws_route53_record" "www" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "www.ganeshc.shop"
  type    = "A"

  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}

# ── A Record: dr.ganeshc.shop → CloudFront ───────────────────
# Uncomment after CloudFront is enabled
# resource "aws_route53_record" "dr" {
#   zone_id = data.aws_route53_zone.main.zone_id
#   name    = "dr.ganeshc.shop"
#   type    = "A"
#
#   alias {
#     name                   = aws_cloudfront_distribution.dr.domain_name
#     zone_id                = aws_cloudfront_distribution.dr.hosted_zone_id
#     evaluate_target_health = false
#   }
# }
