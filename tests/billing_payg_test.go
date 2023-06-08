package tests

import (
	"testing"

	"github.com/rancher/rancher/tests/framework/clients/rancher"
	v1 "github.com/rancher/rancher/tests/framework/clients/rancher/v1"
	"github.com/rancher/rancher/tests/framework/pkg/session"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"github.com/stretchr/testify/suite"
	corev1 "k8s.io/api/core/v1"
)

const (
	PodResourceSteveType             = "pod"
	CspRancherUsageOperatorNameSpace = "cattle-csp-usage-operator-system"
	CspBillingAdapterNameSpace       = "csp-billing-adapter-system"
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
	println(t.totalCurrentManagedNodes)

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
	t.T().Skip("Skipping this test for now. Once we have helm-charts to install csp-adapter, we can enable this")
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

func TestBillingPAYGTestSuite(t *testing.T) {
	suite.Run(t, new(BillingPAYGTestSuite))
}
