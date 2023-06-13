resource "aws_eks_cluster" "main_cluster" {
  name     = "${var.resource_prefix}-cluster"
  role_arn = aws_iam_role.main_cluster_role.arn
  vpc_config {
    subnet_ids = [
      aws_subnet.subnet1.id,
      aws_subnet.subnet2.id,
    ]
  }
  version = var.eks_version

  tags = {
    "owner": var.resource_owner
  }
  depends_on = [aws_iam_role_policy_attachment.main_cluster-AmazonEKSClusterPolicy]
}

resource aws_eks_node_group "main_node_group"{
  cluster_name  = aws_eks_cluster.main_cluster.name
  node_group_name = "${var.resource_prefix}-workers"
  node_role_arn = aws_iam_role.nodes.arn

  subnet_ids = [
      aws_subnet.subnet1.id,
      aws_subnet.subnet2.id
  ]

  scaling_config {
    desired_size = 2
    max_size     = 2
    min_size     = 2
  }
  // these are defaults, including here for clarity
  disk_size = 20
  instance_types = ["t3.medium"]
  tags = {
    "owner": var.resource_owner
  }

  depends_on = [
    aws_iam_role_policy_attachment.nodes-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.nodes-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.nodes-AmazonEC2ContainerRegistryReadOnly,
    aws_internet_gateway.igw
  ]

  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --region ${var.aws_region} --name ${aws_eks_cluster.main_cluster.name} --kubeconfig kubeconfig-e2e.yml"
  }
}

data aws_eks_cluster_auth main_auth{
  name = aws_eks_cluster.main_cluster.name
}

data aws_route53_zone "primary_zone"{
  count = var.zone_name == "" ? 0 : 1

  name = var.zone_name
}

resource "aws_route53_record" "rancher_primary" {
  count = var.zone_name == "" ? 0 : 1

  name    = var.dns_name
  type    = "CNAME"
  ttl     = 60
  records = [data.kubernetes_service.load_balancer_service.status.0.load_balancer.0.ingress.0.hostname]
  zone_id = data.aws_route53_zone.primary_zone[0].id
}
