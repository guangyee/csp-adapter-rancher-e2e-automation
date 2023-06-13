package tests

import (
	"context"

	"github.com/rancher/norman/types"
	"github.com/rancher/rancher/tests/framework/clients/rancher"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime/schema"
)

const (
	PodResourceSteveType             = "pod"
	CspRancherUsageOperatorNameSpace = "cattle-csp-billing-adapter-system"
	CspBillingAdapterNameSpace       = "cattle-csp-billing-adapter-system"
)

var CSPadapterusagerecordsGroupVersionResource = schema.GroupVersionResource{
	Group:    "susecloud.net",
	Version:  "v1",
	Resource: "cspadapterusagerecords",
}

func getTotalCurrentManagedNodes(client *rancher.Client) (int, error) {
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

func getTotalCurrentManagedNodesUsageRecorder(client *rancher.Client) (int, error) {
	//dynamicClient, err := client.GetDownStreamClusterClient("local")

	dynamicClient, err := client.GetRancherDynamicClient()

	if err != nil {
		panic(err.Error())
	}

	cspUsageRecords, err := dynamicClient.Resource(CSPadapterusagerecordsGroupVersionResource).List(context.Background(), metav1.ListOptions{})

	if err != nil {
		// Failed to get usage records
		panic(err.Error())
	}

	count := cspUsageRecords.Items[0].Object["managed_node_count"]
	// count interface {} is int64
	countInt := count.(int64)

	return int(countInt), nil
}
