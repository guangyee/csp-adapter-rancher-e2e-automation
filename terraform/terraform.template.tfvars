# AWS access key used to create infrastructure
aws_access_key = ""

# AWS secret key used to create infrastructure
aws_secret_key = ""

# AWS region used for all resources
aws_region = "us-west-2"

# AWS availability zone 1 for subnet-primary to be used for the EKS cluster subnet_ids
aws_az1 = "us-west-2a"

# AWS availability zone 2 for subnet-secondary to be used for the EKS cluster subnet_ids
aws_az2 = "us-west-2b"

# Resource owner identification - can be an email address
resource_owner = ""

# Prefix of the resources that will be created under this module
resource_prefix = ""

# The id of the zone to make route53 records in - optional, but must be specified if dns_name is specified
zone_name = ""

# The prefix of final dns name for rancher (suffix determined by route53 zone) - optional
dns_name = ""

# Version of cert-manager to install alongside Rancher (format: 0.0.0)
cert_manager_version = "1.11.0"

# Rancher server version (format: v0.0.0)
rancher_version = "2.7.3"

# EKS version
eks_version = "1.24"

# Admin password to use for Rancher server bootstrap, min. 12 characters
rancher_server_admin_password = "r@ncher1234!"

# Rancher image repository
rancher_image_repo = "rancher/rancher"

# Rancher image tag - optional. If not specified, it would be the same as the Rancher chart version.
rancher_image_tag = ""

# Rancher image pull policy
rancher_image_pull_policy = "IfNotPresent"
