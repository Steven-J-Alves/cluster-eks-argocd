#####################################
### HELM RELEASES (cluster addons)
#####################################

# ACK Lambda Controller — manages Lambda functions via K8s CRDs
resource "helm_release" "ack-lambda" {
  name             = "ack-lambda"
  repository       = "oci://public.ecr.aws/aws-controllers-k8s"
  version          = "1.16.1"
  chart            = "lambda-chart"
  namespace        = "ack-lambda"
  create_namespace = "true"
  timeout          = 600

  set {
    name  = "aws.region"
    value = var.aws_region
    type  = "string"
  }
  set {
    name  = "defaultResyncPeriod"
    value = "0"
    type  = "string"
  }

  depends_on = [module.eks]
}

# Local chart that deploys the RunnerDeployment CR consumed by ARC.
resource "helm_release" "crd-helm-chart" {
  name             = "crd-helm-chart"
  chart            = "./crd-helm-chart"
  namespace        = "crd-helm-chart"
  create_namespace = "true"

  set {
    name  = "tag_env"
    value = var.tag_env
    type  = "string"
  }
  set {
    name  = "projectrepo"
    value = var.ci_project_repo
    type  = "string"
  }
  set {
    name  = "aws_account_id"
    value = data.aws_caller_identity.current.account_id
    type  = "string"
  }
  set {
    name  = "aws_region"
    value = var.aws_region
    type  = "string"
  }

  depends_on = [helm_release.actions-runner-controller, helm_release.ack-lambda, module.eks]
}

# cert-manager — TLS cert automation, used by webhooks
resource "helm_release" "cert-manager" {
  name             = "cert-manager"
  chart            = "cert-manager"
  repository       = "https://charts.jetstack.io"
  namespace        = "cert-manager"
  version          = "1.16.5"
  create_namespace = "true"

  set {
    name  = "installCRDs"
    value = true
  }

  depends_on = [module.eks]
}

# actions-runner-controller — self-hosted GitHub Actions runners in EKS
resource "helm_release" "actions-runner-controller" {
  name             = "actions-runner-controller"
  chart            = "actions-runner-controller"
  repository       = "https://actions-runner-controller.github.io/actions-runner-controller"
  namespace        = "actions-runner-system"
  version          = "0.23.7"
  create_namespace = "true"

  set {
    name  = "authSecret.create"
    value = "true"
    type  = "string"
  }
  set {
    name  = "authSecret.github_token"
    value = var.registrationToken
    type  = "string"
  }

  depends_on = [helm_release.cert-manager, module.eks]
}

# nginx ingress controller — creates the NLB
resource "helm_release" "ingress-nginx" {
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  version          = "4.12.2"
  namespace        = "ingress-nginx"
  create_namespace = "true"
  timeout          = 600

  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-connection-idle-timeout"
    value = "60"
    type  = "string"
  }
  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-cross-zone-load-balancing-enabled"
    value = "true"
    type  = "string"
  }
  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-ssl-cert"
    value = module.acm_route53.certificate_arn
    type  = "string"
  }
  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-ssl-ports"
    value = "https"
    type  = "string"
  }
  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-ssl-negotiation-policy"
    value = "ELBSecurityPolicy-TLS-1-2-2017-01"
    type  = "string"
  }
  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-type"
    value = "nlb"
    type  = "string"
  }
  set {
    name  = "controller.service.targetPorts.http"
    value = "http"
    type  = "string"
  }
  set {
    name  = "controller.service.targetPorts.https"
    value = "http"
    type  = "string"
  }
  set {
    name  = "controller.admissionWebhooks.enabled"
    value = "false"
  }

  depends_on = [module.eks]
}

# ArgoCD server (chart 7.x — server.insecure moved to configs.params)
resource "helm_release" "argocd" {
  name             = "argocd"
  create_namespace = "true"
  chart            = "argo-cd"
  namespace        = "argocd"
  version          = "7.7.19"
  repository       = "https://argoproj.github.io/argo-helm"
  timeout          = 600

  set {
    name  = "configs.params.server\\.insecure"
    value = "true"
    type  = "string"
  }
  set {
    name  = "server.ingress.enabled"
    value = "true"
    type  = "string"
  }
  set {
    name  = "server.ingress.ingressClassName"
    value = "nginx"
    type  = "string"
  }
  set {
    name  = "server.ingress.annotations.nginx\\.ingress\\.kubernetes\\.io/force-ssl-redirect"
    value = "false"
    type  = "string"
  }
  set {
    name  = "server.ingress.annotations.nginx\\.ingress\\.kubernetes\\.io/backend-protocol"
    value = "HTTP"
    type  = "string"
  }
  set {
    name  = "server.ingress.hostname"
    value = "argo.${var.tag_env}.${var.base_domain}"
    type  = "string"
  }

  depends_on = [module.eks]
}

# ArgoCD Application CRs (chart 2.x uses MAP for applications)
resource "helm_release" "argocd-apps" {
  name       = "argocd-apps"
  chart      = "argocd-apps"
  namespace  = "argocd"
  version    = "2.0.2"
  repository = "https://argoproj.github.io/argo-helm"
  timeout    = 300

  set {
    name  = "applications.demo.source.repoURL"
    value = "${var.gitlab_url}/${var.cd_project_repo}.git"
    type  = "string"
  }
  set {
    name  = "applications.demo.source.targetRevision"
    value = var.tag_env
    type  = "string"
  }
  values = [file("${path.module}/helm-chart-values/argo-cd-apps-values.yaml")]

  depends_on = [helm_release.argocd, module.eks]
}
