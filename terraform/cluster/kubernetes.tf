resource "kubernetes_namespace" "application" {
  metadata { name = "application" }
  depends_on = [module.eks]
}

# ArgoCD repo credentials — how ArgoCD authenticates to the manifests repo
resource "kubernetes_secret" "cd_repo" {
  metadata {
    name      = "${var.tag_env}-repo"
    namespace = "argocd"
    labels = {
      "argocd.argoproj.io/secret-type" = "repository"
    }
    annotations = {
      "kubernetes.io/service-account.name" = "my-service-account"
    }
  }
  data = {
    username = "root"
    password = var.gitlab_token
    type     = "git"
    url      = "${var.gitlab_url}/${var.cd_project_repo}.git"
  }
  type       = "Opaque"
  depends_on = [helm_release.argocd, module.eks]
}

data "kubernetes_service" "ingress_gateway" {
  metadata {
    name      = "ingress-nginx-controller"
    namespace = helm_release.ingress-nginx.namespace
  }
  depends_on = [helm_release.ingress-nginx, module.eks]
}
