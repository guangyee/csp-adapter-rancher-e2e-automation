output "kubeconfig-generate" {
  value = "Run the following command to generate a kubeconfig: aws eks update-kubeconfig --region us-east-1 --name  ${aws_eks_cluster.main_cluster.name} --kubeconfig kubeconfig.yml"
}

output rancher_hostname {
  value = var.zone_name == "" ? data.kubernetes_service.load_balancer_service.status.0.load_balancer.0.ingress.0.hostname : aws_route53_record.rancher_primary[0].fqdn
}
