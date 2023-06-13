package tests

import (
	"fmt"
	"testing"

	"github.com/rancher/rancher/tests/framework/clients/rancher"
	management "github.com/rancher/rancher/tests/framework/clients/rancher/generated/management/v3"
	v1 "github.com/rancher/rancher/tests/framework/clients/rancher/v1"
	"github.com/rancher/rancher/tests/framework/extensions/cloudcredentials/aws"
	"github.com/rancher/rancher/tests/framework/extensions/clusters"
	"github.com/rancher/rancher/tests/framework/extensions/clusters/eks"
	nodestat "github.com/rancher/rancher/tests/framework/extensions/nodes"
	"github.com/rancher/rancher/tests/framework/extensions/pipeline"
	"github.com/rancher/rancher/tests/framework/extensions/workloads/pods"
	"github.com/rancher/rancher/tests/framework/pkg/environmentflag"
	namegen "github.com/rancher/rancher/tests/framework/pkg/namegenerator"
	"github.com/rancher/rancher/tests/framework/pkg/session"
	"github.com/rancher/rancher/tests/framework/pkg/wait"
	"github.com/rancher/rancher/tests/v2prov/defaults"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"github.com/stretchr/testify/suite"
	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/watch"
)

type BillingPAYGTestSuite struct {
	suite.Suite
	client                   *rancher.Client
	session                  *session.Session
	clusterLocalID           string
	totalCurrentManagedNodes int
}

func (t *BillingPAYGTestSuite) TearDownSuite() {
	t.session.Cleanup()
}

func (t *BillingPAYGTestSuite) SetupSuite() {
	testSession := session.NewSession()
	t.session = testSession

	client, err := rancher.NewClient("", testSession)
	require.NoError(t.T(), err)

	t.client = client
	t.clusterLocalID = "local"

	// Rancher instance against which this test is run may already have some managed nodes.
	// Track this count before the tests begin.
	totalCurrentManagedNodes, err := getTotalCurrentManagedNodes(client)
	if err != nil {
		assert.Fail(t.T(), "Cannot retrieve the total number of currently managed nodes")
	}
	t.totalCurrentManagedNodes = totalCurrentManagedNodes

}

func (t *BillingPAYGTestSuite) TestValidateCSPRancherUsageOperatorPodStatus() {
	c, err := t.client.Steve.ProxyDownstream(t.clusterLocalID)
	require.NoError(t.T(), err, "Unable to create the client")
	steveClient := c.SteveType(PodResourceSteveType).NamespacedSteveClient(CspRancherUsageOperatorNameSpace)
	pods, err := steveClient.List(nil)
	assert.NoError(t.T(), err, "Unable to list the pods")

	podStatus := &corev1.PodStatus{}
	// Expecting the pod in the namespace to be Running
	msg := "Expecting pod to be running in %s" + CspRancherUsageOperatorNameSpace
	assert.Condition(t.T(), func() bool {
		return len(pods.Data) > 0
	}, msg)

	err = v1.ConvertToK8sType(pods.Data[0].Status, podStatus)
	assert.NoError(t.T(), err, "Unable to convert to k8s type")

	phase := podStatus.Phase
	assert.Equal(t.T(), phase, corev1.PodRunning)

}

func (t *BillingPAYGTestSuite) TestValidateCSPBillingAdapterPodStatus() {
	c, err := t.client.Steve.ProxyDownstream(t.clusterLocalID)
	require.NoError(t.T(), err, "Unable to create the client")
	steveClient := c.SteveType(PodResourceSteveType).NamespacedSteveClient(CspBillingAdapterNameSpace)
	pods, err := steveClient.List(nil)
	assert.NoError(t.T(), err, "Unable to list the pods")
	podStatus := &corev1.PodStatus{}
	// Expecting the pod in the namespace to be Running
	msg := "Expecting pod to be running in %s" + CspBillingAdapterNameSpace
	assert.Condition(t.T(), func() bool {
		return len(pods.Data) > 0
	}, msg)
	err = v1.ConvertToK8sType(pods.Data[0].Status, podStatus)
	assert.NoError(t.T(), err, "Unable to convert to k8s type")

	phase := podStatus.Phase
	assert.Equal(t.T(), phase, corev1.PodRunning)

}

func (t *BillingPAYGTestSuite) TestValidateTotalCountAfterProvisioningHostedEKSCluster() {
	//t.T().Skip("Skipping this test for now. Running into https://github.com/rancher/rancher/issues/41123")

	subSession := t.session.NewSession()
	defer subSession.Cleanup()

	client, err := t.client.WithSession(subSession)
	require.NoError(t.T(), err)

	cloudCredential, err := aws.CreateAWSCloudCredentials(client)
	require.NoError(t.T(), err)

	clusterName := namegen.AppendRandomString("ekshostclusterb")
	clusterResp, err := eks.CreateEKSHostedCluster(client, clusterName, cloudCredential.ID, false, false, false, false, map[string]string{})
	require.NoError(t.T(), err)

	if client.Flags.GetValue(environmentflag.UpdateClusterName) {
		pipeline.UpdateConfigClusterName(clusterName)
	}

	opts := metav1.ListOptions{
		FieldSelector:  "metadata.name=" + clusterResp.ID,
		TimeoutSeconds: &defaults.WatchTimeoutSeconds,
	}
	watchInterface, err := client.GetManagementWatchInterface(management.ClusterType, opts)
	require.NoError(t.T(), err)

	checkFunc := clusters.IsHostedProvisioningClusterReady

	err = wait.WatchWait(watchInterface, checkFunc)
	require.NoError(t.T(), err)
	assert.Equal(t.T(), clusterName, clusterResp.Name)

	clusterToken, err := clusters.CheckServiceAccountTokenSecret(client, clusterName)
	require.NoError(t.T(), err)
	assert.NotEmpty(t.T(), clusterToken)

	err = nodestat.IsNodeReady(client, clusterResp.ID)
	require.NoError(t.T(), err)

	podResults, podErrors := pods.StatusPods(client, clusterResp.ID)
	assert.NotEmpty(t.T(), podResults)
	assert.Empty(t.T(), podErrors)

	//VALIDATE that the managed_node_count reported in the csprancherusagerecords CRD is equal to
	// [t.totalCurrentManagedNodes + 2 nodes created in this test]

	nodeCount, err := getTotalCurrentManagedNodesUsageRecorder(client)
	if err != nil {
		assert.Fail(t.T(), "Could not retrieve the usage records")
	}

	// 2 is the count specified in the cattle-config yaml file for provisioning
	assert.Equal(t.T(), t.totalCurrentManagedNodes+2, nodeCount)

	// ADD any other validations here

	// Cleanup provisioned cluster
	client.Session.RegisterCleanupFunc(func() error {
		adminClient, err := rancher.NewClient(client.RancherConfig.AdminToken, client.Session)
		if err != nil {
			return err
		}

		clusterResp, err := client.Management.Cluster.ByID(clusterResp.ID)
		if err != nil {
			return err
		}

		client, err = client.ReLogin()
		if err != nil {
			return err
		}

		err = client.Management.Cluster.Delete(clusterResp)
		if err != nil {
			return err
		}

		watchInterface, err := adminClient.GetManagementWatchInterface(management.ClusterType, metav1.ListOptions{
			FieldSelector:  "metadata.name=" + clusterResp.ID,
			TimeoutSeconds: &defaults.WatchTimeoutSeconds,
		})
		if err != nil {
			return err
		}

		return wait.WatchWait(watchInterface, func(event watch.Event) (ready bool, err error) {
			if event.Type == watch.Error {
				return false, fmt.Errorf("there was an error deleting cluster")
			} else if event.Type == watch.Deleted {
				return true, nil
			}
			return false, nil
		})
	})

}

func TestBillingPAYGTestSuite(t *testing.T) {
	suite.Run(t, new(BillingPAYGTestSuite))
}
