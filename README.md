## csp-adapter-rancher-e2e-automation

CSP Billing Adapter Rancher End-to-End Automation

This repo contains deployment and test scripts for testing the csp-billing-adapter for rancher in all the three cloud service providers - AWS, GCP and Azure.


### Terraform for deployment

Terraform which creates the [pre-requisites](https://ranchermanager.docs.rancher.com/integrations-in-rancher/cloud-marketplace/aws-cloud-marketplace/adapter-requirements) for the csp adapter install. 

### Tests

These tests make use of the rancher test [framework](https://github.com/rancher/rancher/tree/release/v2.7/tests/framework) 
for testing the billing feature. Rancher test framework is written in go. 

Go must be installed on the local machine where you are runnig the tests.

After cloning this repo, run ```go mod download```

To run the billing tests, you'll need to create an environment variable: CATTLE_TEST_CONFIG (path to config file).

As an example:
export CATTLE_TEST_CONFIG=/home/<user>/cattle-config.yaml

An example of cattle-config.yaml:
```
rancher:
  host: "enter your host here, it can be yours.qa.rancher.space or an IP address"
  adminToken: "generate an admin token from your rancher and enter it here"
```

The automated tests in this repo can be run on the command-line, example:

```
/usr/local/go/bin/go test -timeout 60m -run ^TestBillingPAYGTestSuite$ csp-adapter-rancher-e2e-automation/tests
```

You can also run it in verbose mode with the -v option.
Example:
```
/usr/local/go/bin/go test -timeout 60m -run ^TestBillingPAYGTestSuite$ csp-adapter-rancher-e2e-automation/tests -v
=== RUN   TestBillingPAYGTestSuite
time="2023-06-05T13:59:10-07:00" level=info msg="Dynamic Client Host:https://metal3-core.suse.baremetal/k8s/clusters/local"
0
=== RUN   TestBillingPAYGTestSuite/TestValidateCSPBillingAdapterPodStatus
    billing_payg_test.go:76: Skipping this test for now. Once we have helm-charts to install csp-adapter, we can enable this
=== RUN   TestBillingPAYGTestSuite/TestValidateCSPRancherUsageOperatorPodStatus
--- PASS: TestBillingPAYGTestSuite (4.15s)
    --- SKIP: TestBillingPAYGTestSuite/TestValidateCSPBillingAdapterPodStatus (0.00s)
    --- PASS: TestBillingPAYGTestSuite/TestValidateCSPRancherUsageOperatorPodStatus (0.96s)
PASS
ok  	csp-adapter-rancher-e2e-automation/tests	4.187s
```
