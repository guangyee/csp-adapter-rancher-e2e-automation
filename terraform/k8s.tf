/*
K8s related resources (includes helm charts and the like)
*/

provider "kubernetes"{
  host                   = aws_eks_cluster.main_cluster.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.main_cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.main_auth.token
}

provider "helm"{
  kubernetes {
    host                   = aws_eks_cluster.main_cluster.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.main_cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.main_auth.token
  }
}

resource helm_release "ingress-nginx"{
  depends_on = [aws_eks_node_group.main_node_group]
  name = "ingress-nginx"
  chart = "ingress-nginx/ingress-nginx"
  namespace = "ingress-nginx"
  version = "4.2.0"
  create_namespace = true
  set {
    name  = "controller.service.type"
    value = "LoadBalancer"
  }
  set {
    name = "controller.watchIngressWithoutClass"
    value = true
  }
}

resource kubernetes_namespace "cattle-system"{
  depends_on = [aws_eks_node_group.main_node_group]
  metadata {
    name = "cattle-system"
  }
}

data kubernetes_service load_balancer_service{
  depends_on = [helm_release.ingress-nginx, aws_eks_node_group.main_node_group]
  metadata{
    name = "ingress-nginx-controller"
    namespace = helm_release.ingress-nginx.namespace
  }
}

resource helm_release "cert-manager"{
  depends_on = [aws_eks_node_group.main_node_group]
  name  = "cert-manager"
  chart = "jetstack/cert-manager"
  namespace = "cert-manager"
  create_namespace = true
  version = var.cert_manager_version 
  set {
    name  = "installCRDs"
    value = "true"
  }
}

resource "helm_release" "rancher"{
  // can't install rancher until we have dns, cert-manager, and the cattle-system namespace
  depends_on = [kubernetes_namespace.cattle-system, helm_release.cert-manager, data.kubernetes_service.load_balancer_service]
  name = "rancher"
  chart = "rancher-latest/rancher"
  namespace = "cattle-system"
  version = var.rancher_version
  set {
    name  = "hostname"
    value = var.zone_name == "" ? data.kubernetes_service.load_balancer_service.status.0.load_balancer.0.ingress.0.hostname : aws_route53_record.rancher_primary[0].fqdn
  }
  set {
    name = "global.cattle.psp.enabled"
    value = false
  }
  values = [yamlencode({
  extraEnv: [
    {
      name: "CATTLE_PROMETHEUS_METRICS",
      value: "true"
    },
  ]})]
}
