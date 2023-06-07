## Terraform module for csp-adapter pre-requisistes 

## Variables

See variables.tf for a full list of variables.

## Notes

## Deployment

Before running the terraform, you need install terraform/helm. You also need to instantiate the required repos for the helm provider, see below:

Refer to the installation instructions:
For terraform at: https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli
For helm at: https://helm.sh/docs/intro/install/


```bash
helm repo add rancher-latest https://releases.rancher.com/server-charts/latest 
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo add jetstack https://charts.jetstack.io 
```

One can create a terraform.tfvars to manage the variable assignments. A sample terraform.template.tfvars is provided to create the terraform.tfvars file.

```bash
cd terraform
cp terraform.template.tfvars terraform.tfvars
```

Update terraform.tfvars accordingly

To proceed with the deployment process.

```bash
terraform init
terraform plan
terraform apply
```

The command ```terraform output``` shows the commands to generate the kubeconfig for the cluster created and also shows the rancher hostname.

## Cleanup

To cleanup resources maintained by terraform, run

```bash
terraform destroy
```

## Cleanup Troubleshooting

Rancher adds finalizers to certain resources once installed in a project. This can lead to issues when uninstalling rancher/related components (rancher is uninstalled before it can remove the finalizers, and it is no longer around to remove other finalizers once those components are uninstalled).

Since terraform does not allow skipping resources on delete (https://github.com/hashicorp/terraform/issues/23547), you'll need to remove these resources from the state file so that the delete process can proceed.

If encountering a timeout error with the helm_release.rancher deletion the following workaround can be used:

```bash
terraform state rm helm_release.cert-manager
terraform state rm helm_release.rancher
terraform state rm kubernetes_namespace.cattle-system
terraform destroy
```
