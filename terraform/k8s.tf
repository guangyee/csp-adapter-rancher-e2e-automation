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
  wait = true
  timeout = 300
  wait_for_jobs = true
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
  wait = true
  timeout = 300
  wait_for_jobs = true
}

resource "helm_release" "rancher"{
  // can't install rancher until we have dns, cert-manager, and the cattle-system namespace
  depends_on = [kubernetes_namespace.cattle-system, helm_release.cert-manager, data.kubernetes_service.load_balancer_service]
  name = "rancher"
  chart = "rancher-latest/rancher"
  namespace = "cattle-system"
  version = var.rancher_version
  wait = true
  timeout = 300
  wait_for_jobs = true
  set {
    name  = "hostname"
    value = var.zone_name == "" ? data.kubernetes_service.load_balancer_service.status.0.load_balancer.0.ingress.0.hostname : aws_route53_record.rancher_primary[0].fqdn
  }
  set {
    name = "global.cattle.psp.enabled"
    value = false
  }
  set {
    name  = "bootstrapPassword"
    value = var.rancher_server_admin_password
  }
  set {
    name = "installCRDs"
    value = "true"
  }
  values = [yamlencode({
  extraEnv: [
    {
      name: "CATTLE_PROMETHEUS_METRICS",
      value: "true"
    },
    {
      name: "CATTLE_SERVER_URL",
      value: format("%s%s","https://",var.zone_name == "" ? data.kubernetes_service.load_balancer_service.status.0.load_balancer.0.ingress.0.hostname : aws_route53_record.rancher_primary[0].fqdn)
    },
  ]})]
}

locals {
  password = var.rancher_server_admin_password
  rancher_url = format("%s%s","https://",var.zone_name == "" ? data.kubernetes_service.load_balancer_service.status.0.load_balancer.0.ingress.0.hostname : aws_route53_record.rancher_primary[0].fqdn)
  rancher_host = var.zone_name == "" ? data.kubernetes_service.load_balancer_service.status.0.load_balancer.0.ingress.0.hostname : aws_route53_record.rancher_primary[0].fqdn
}

# Get the admin token to populate the cattle-config-e2e.yaml which is the input to the tests
data "external" "get-token" {
  depends_on = [helm_release.rancher]
  program = ["sh", "${path.module}/get_rancher_admin_token.sh", "${local.rancher_url}", "admin", "${var.rancher_server_admin_password}"]
}

# Create the cattle-config-e2e.yaml which is the input to the tests
resource "local_file" "cattle-config-e2e-yaml" {
  # cattle-config yaml for running the tests
  depends_on = [data.external.get-token]
  filename = "cattle-config-e2e.yaml"
  content = <<EOF
rancher:
  host: ${local.rancher_host}
  adminToken: ${data.external.get-token.result.token}
  cleanup: true
awsCredentials:
  secretKey: ${var.aws_secret_key}
  accessKey: ${var.aws_access_key}
  defaultRegion: ${var.aws_region}
eksClusterConfig:
  imported: false
  kmsKey: ""
  kubernetesVersion: "1.24"
  loggingTypes: []
  nodeGroups:
  - desiredSize: 2
    diskSize: 20
    ec2SshKey: ""
    gpu: false
    imageId: ""
    instanceType: t3.medium
    labels: {}
    maxSize: 3
    minSize: 2
    nodegroupName: ${var.resource_prefix}-e2e-nodegroup
    requestSpotInstances: false
    resourceTags: {}
    spotInstanceTypes: []
    subnets: []
    tags: {}
    userData: ""
    version: "1.24"
    nodeRole: ""
  privateAccess: false
  publicAccess: true
  publicAccessSources: []
  region: ${var.aws_region}
  secretsEncryption: false
  securityGroups:
  - ${aws_security_group.sg_allowall.id}
  serviceRole: ""
  subnets:
  - ${aws_subnet.subnet1.id}
  - ${aws_subnet.subnet2.id}
  tags: {}

EOF
}

resource "kubernetes_namespace" "cattle-csp-billing-adapter-system" {
  metadata {
    name = var.namespace
  }
}

resource "null_resource" "secret" {
  depends_on = [kubernetes_namespace.cattle-system, helm_release.rancher, kubernetes_namespace.cattle-csp-billing-adapter-system ]
  triggers = {
    always_run = "${timestamp()}"
  }
  provisioner "local-exec" {
    command = <<-EOT
      if KUBECONFIG=kubeconfig-e2e.yml kubectl get secret tls-ca-additional -n ${var.namespace} >/dev/null 2>&1; then
        KUBECONFIG=kubeconfig-e2e.yml kubectl delete secret tls-ca-additional -n ${var.namespace}
        sleep 5
      fi
      KUBECONFIG=kubeconfig-e2e.yml kubectl get secret tls-rancher -n cattle-system -o jsonpath="{.data.tls\\.crt}" | base64 -d > ca-additional.pem
      KUBECONFIG=kubeconfig-e2e.yml kubectl create secret generic tls-ca-additional -n ${var.namespace} --from-file=ca-additional.pem
      sleep 15
    EOT
    interpreter = ["/bin/bash", "-c"]
  }
}

# Install charts from the git repo until the helm charts are published
resource "null_resource" "git_clone" {
  provisioner "local-exec" {
    command = "if [ ! -d csp-rancher-usage-operator ]; then git clone --branch ${var.helm_chart_repo_branch} ${var.helm_chart_repo_url} csp-rancher-usage-operator; else rm -rf csp-rancher-usage-operator; git clone --branch ${var.helm_chart_repo_branch} ${var.helm_chart_repo_url} csp-rancher-usage-operator; fi"
  }
}

# Install the csp-adapter-crd from the git repo until the helm charts are published
resource "helm_release" "csp-adapter-crd" {
  depends_on = [kubernetes_namespace.cattle-csp-billing-adapter-system, helm_release.rancher, null_resource.secret ]
  name = "csp-adapter-crd"
  chart      = "./csp-rancher-usage-operator/charts/csp-adapter-crd/${var.csp_adapter_crd_chart_version}"
  namespace  = var.namespace
  wait = true
  timeout = 180
}

# Install the csp-rancher-usage-operator from the git repo until the helm charts are published
resource "helm_release" "csp-rancher-usage-operator" {
  depends_on = [kubernetes_namespace.cattle-csp-billing-adapter-system, helm_release.rancher, null_resource.secret ]
  name = "csp-rancher-usage-operator"
  chart      = "./csp-rancher-usage-operator/charts/csp-rancher-usage-operator/${var.csp_rancher_usage_operator_chart_version}"
  namespace  = var.namespace
  wait = true
  timeout = 180
  set {
    name = "additionalTrustedCAs"
    value = true
  }
}

# Install rancher-csp-billing-adapter chart from the git repo until the helm charts are published
resource "helm_release" "rancher-csp-billing-adapter" {
  depends_on = [kubernetes_namespace.cattle-csp-billing-adapter-system]
  name = "rancher-csp-billing-adapter"
  chart      = "./csp-rancher-usage-operator/charts/rancher-csp-billing-adapter/${var.rancher_csp_billing_adapter_chart_version}"
  namespace  = var.namespace
  wait = true
  timeout = 180
}