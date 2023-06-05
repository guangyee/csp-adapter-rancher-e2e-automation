variable "resource_owner" {
  type = string
  description = "email address of the owning user - used to identify resource owner"
}

variable "resource_prefix"{
  type = string
  description = "prefix of the resources that will be created under this module"
}

variable "cluster_role_name" {
  type = string
  description = "The name of the role to use for the eks cluster role"
}

variable "node_role_name" {
  type = string
  description = "The name of the role to use for the eks cluster nodes"
}

variable "vpc_id"{
  type = string
  description = "The id of the vpc to create the cluster in"
}

variable "zone_name"{
  type = string
  description = "the id of the zone to make route53 records in - optional, but must be specified if dns_name is"
  default = ""
}

variable "dns_name" {
  type = string
  description = "the prefix of final dns name for rancher (suffix determined by route53 zone) - optional, but must "
  default = ""
}

variable "rancher_version"{
  type = string
  description = "the version of rancher. Must be compatable with the cert-manager/eks version"
  default = "2.7.3"
}

variable "cert_manager_version"{
  type = string
  description = "the version of cert-manager. Must be compatable with rancher/eks version"
  default = "1.7.1"
}

variable "eks_version"{
  type = string
  description = "the eks version. Must be compatable with cert-manager/rancher version"
  default = "1.24"
}
