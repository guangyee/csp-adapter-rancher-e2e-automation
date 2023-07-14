## Terraform module for csp-adapter pre-requisistes 

## Variables

See variables.tf for a full list of variables.

## Notes

## Deployment

Before running these terraform scripts, you need to install few utilities:

Refer to the installation instructions:

- terraform: https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli
- helm: https://helm.sh/docs/intro/install/
- aws cli: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
- kubectl: https://docs.aws.amazon.com/eks/latest/userguide/install-kubectl.html

Please make sure the version of the cli is compatible with the EKS cluster version.

- Install jq via your package manager. jq is a command line based JSON processor that allows for operations on JSON data. This utility is needed by the get_rancher_admin_token.sh script.

Instantiate the required repos for the helm provider, see below:

```bash
helm repo add rancher-latest https://releases.rancher.com/server-charts/latest 
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo add jetstack https://charts.jetstack.io
helm repo update
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

Rancher adds finalizers to certain resources once installed in a project. This can lead to issues when uninstalling rancher/related components (rancher is uninstalled before it can remove the finalizers, and it is no longer around to remove other finalizers once those components are uninstalled).

Since terraform does not allow skipping resources on delete (https://github.com/hashicorp/terraform/issues/23547), you'll need to remove these resources from the state file so that the delete process can proceed.

NOTE: 
Before destroy, make sure to clean up any manually created rancher managed clusters in the CSP as terraform is not aware of these out of band resources created.

The following set of commands need to be run to cleanup up the resources created by terraform:

```bash
terraform state rm helm_release.cert-manager
terraform state rm helm_release.rancher
terraform state rm kubernetes_namespace.cattle-system
terraform state rm kubernetes_namespace.cattle-csp-billing-adapter-system
terraform destroy
```
