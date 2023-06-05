/*
Permissions related to the OIDC/IRSA (IAM roles for service accounts) integration
*/

data tls_certificate "cluster_cert"{
  url = aws_eks_cluster.main_cluster.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "main_provider" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.cluster_cert.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.main_cluster.identity[0].oidc[0].issuer
  tags = {"owner": var.resource_owner}
}

data aws_iam_policy_document "adapter_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      values   = ["system:serviceaccount:cattle-csp-adapter-system:rancher-csp-adapter"]
      variable = "${replace(aws_iam_openid_connect_provider.main_provider.url, "https://", "")}:sub"
    }
    condition {
      test     = "StringEquals"
      values   = ["sts.amazonaws.com"]
      variable = "${replace(aws_iam_openid_connect_provider.main_provider.url, "https://", "")}:aud"
    }
    principals {
      identifiers = [aws_iam_openid_connect_provider.main_provider.arn]
      type        = "Federated"
    }
  }
}

data aws_iam_policy_document "adapter_permissions"{
  statement {
    actions = [
      "license-manager:ListReceivedLicenses",
      "license-manager:CheckoutLicense",
      "license-manager:ExtendLicenseConsumption",
      "license-manager:CheckInLicense",
      "license-manager:GetLicense",
      "license-manager:GetLicenseUsage"
    ]
    effect = "Allow"
    resources = ["*"]
  }
}

resource "aws_iam_role" "csp-adapter-role"{
  name = "${var.resource_prefix}-role"
  assume_role_policy = data.aws_iam_policy_document.adapter_assume_role.json
  inline_policy {
    name = "AdapterPermissions"
    policy = data.aws_iam_policy_document.adapter_permissions.json
  }
}