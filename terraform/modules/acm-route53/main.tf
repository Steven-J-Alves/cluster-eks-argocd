data "aws_route53_zone" "base" {
  name = var.base_domain
}

resource "aws_acm_certificate" "cert" {
  domain_name               = "${var.tag_env}.${var.base_domain}"
  subject_alternative_names = ["*.${var.tag_env}.${var.base_domain}"]
  validation_method         = "DNS"

  tags = { Name = "${var.tag_env}.${var.base_domain}" }
}

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }
  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.base.zone_id
}

resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for r in aws_route53_record.cert_validation : r.fqdn]
}

# Wildcard record pointing to the NLB created by ingress-nginx
resource "aws_route53_record" "wildcard" {
  zone_id = data.aws_route53_zone.base.id
  name    = "*"
  type    = "A"

  alias {
    name                   = var.nlb_dns_name
    zone_id                = var.nlb_zone_id
    evaluate_target_health = true
  }
}

# Bastion record
resource "aws_route53_record" "bastion" {
  zone_id = data.aws_route53_zone.base.id
  name    = "bastion.${var.tag_env}.${var.base_domain}"
  type    = "A"
  ttl     = 300
  records = [var.bastion_public_ip]
}
