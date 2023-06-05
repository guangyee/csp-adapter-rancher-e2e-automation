package tests

import (
	"github.com/rancher/norman/types"
	"github.com/rancher/rancher/tests/framework/clients/rancher"
)

func getTotalCurrentManagedNodes(client *rancher.Client) (totalCurrentManagedNodes int, err error) {
	localNodes, err := client.Management.Node.List(&types.ListOpts{
		Filters: map[string]interface{}{
			"clusterId": "local",
		},
	})
	if err != nil {
		return 0, err
	}

	allNodes, err := client.Management.Node.List(&types.ListOpts{})
	if err != nil {
		return 0, err
	}

	return len(allNodes.Data) - len(localNodes.Data), err
}
