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
    external = {
      source = "hashicorp/external"
      version = "~> 2.3"
    }
    null = {
      source = "hashicorp/null"
      version = "~> 3.2"
    }
    tls = {
      source = "hashicorp/tls"
      version = "~>4.0"
    }
    local = {
      source = "hashicorp/local"
      version = "~>2.4.0"
    }
  }
  required_version = ">= 1.2"
}
provider "aws" {
  region = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}
