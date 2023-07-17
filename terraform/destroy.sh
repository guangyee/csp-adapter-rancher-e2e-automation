#!/bin/bash

terraform state rm helm_release.cert-manager
terraform state rm helm_release.rancher
terraform state rm kubernetes_namespace.cattle-system
terraform state rm kubernetes_namespace.cattle-csp-billing-adapter-system
terraform destroy
