data aws_iam_role cluster_role{
  name = var.cluster_role_name
}

data aws_iam_role node_role{
  name = var.node_role_name
}

data aws_subnets subnets{
  filter{
    name   = "vpc-id"
    values = [var.vpc_id]
  }
  filter{
    name = "availability-zone"
    values = ["us-east-1a", "us-east-1b","us-east-1c","us-east-1d","us-east-1f"]
  }
}

resource "aws_eks_cluster" "main_cluster" {
  name     = "${var.resource_prefix}-cluster"
  role_arn = data.aws_iam_role.cluster_role.arn
  vpc_config {
    subnet_ids = toset(data.aws_subnets.subnets.ids)
  }
  version = var.eks_version
  tags = {
    "owner": var.resource_owner
  }
}

resource aws_eks_node_group "main_node_group"{
  cluster_name  = aws_eks_cluster.main_cluster.name
  node_group_name = "${var.resource_prefix}-workers"
  node_role_arn = data.aws_iam_role.node_role.arn
  subnet_ids    = toset(data.aws_subnets.subnets.ids)
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
