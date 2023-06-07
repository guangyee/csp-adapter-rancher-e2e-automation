variable "aws_access_key" {
  type = string
  description = "AWS access key"
}

variable "aws_secret_key" {
  type = string
  description = "AWS secret key."
}

variable "aws_region" {
  type = string
  description = "AWS region to launch resources"
}

variable "aws_az1" {
  type = string
  description = "AWS availability zone 1"
}

variable "aws_az2" {
  type = string
  description = "AWS availability zone 2"
}

variable "resource_owner" {
  type = string
  description = "email address of the owning user - used to identify resource owner"
}

variable "resource_prefix"{
  type = string
  description = "prefix of the resources that will be created under this module"
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

variable "rancher_server_admin_password" {
  type        = string
  description = "Admin password to use for Rancher server bootstrap, min. 12 characters"
}