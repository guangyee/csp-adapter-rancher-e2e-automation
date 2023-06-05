terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 3.0"
    }
    helm = {
      source = "hashicorp/helm"
      version = "~> 2.5"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "~> 2.11"
    }
  }
}
