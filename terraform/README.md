## Terraform module for csp-adapter pre-requisistes 

## Variables

See variables.tf for a full list of variables.

## Notes

Before running the terraform, you need install terraform/helm. You also need to instantiate the required repos for the helm provider, see below:


```bash
helm repo add rancher-latest https://releases.rancher.com/server-charts/latest 
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo add jetstack https://charts.jetstack.io 
```

Rancher adds finalizers to certain resources once installed in a project. This can lead to issues when uninstalling rancher/related components (rancher is uninstalled before it can remove the finalizers, and it is no longer around to remove other finalizers once those components are uninstalled).

Since terraform does not allow skipping resources on delete (https://github.com/hashicorp/terraform/issues/23547), you'll need to remove these resources from the state file so that the delete process can proceed.

Run the following commands:

```bash
tf state rm helm_release.cert-manager
tf state rm helm_release.rancher
```
