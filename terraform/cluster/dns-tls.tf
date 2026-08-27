data "aws_lb" "ingress" {
  name = regex(
    "(^[^-]+)",
    data.kubernetes_service.ingress_gateway.status[0].load_balancer[0].ingress[0].hostname
  )[0]
}

module "acm_route53" {
  source            = "../modules/acm-route53"
  tag_env           = var.tag_env
  base_domain       = var.base_domain
  nlb_dns_name      = data.kubernetes_service.ingress_gateway.status[0].load_balancer[0].ingress[0].hostname
  nlb_zone_id       = data.aws_lb.ingress.zone_id
  bastion_public_ip = module.bastion.public_ip
}
