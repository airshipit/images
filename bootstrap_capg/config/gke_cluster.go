/*
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

     https://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
*/

package config

import (
	"log"
	"os"
	"strconv"
)

const (
	gcloud                 = "gcloud"
	auth                   = "auth"
	activateServiceAccount = "activate-service-account"
	config                 = "config"
	set                    = "set"
	project                = "project"
	container              = "container"
	clusters               = "clusters"
	create                 = "create"
	delete                 = "delete"
	getCredentials         = "get-credentials"

	zoneP                        = "--zone"
	nodeLocations                = "--node-locations"
	keyFileP                     = "--key-file"
	clusterVersionP              = "--cluster-version"
	machineTypeP                 = "--machine-type"
	numNodesP                    = "--num-nodes"
	enableIPAlias                = "--enable-ip-alias"
	imageTypeP                   = "--image-type"
	diskTypeP                    = "--disk-type"
	diskSizeP                    = "--disk-size"
	metadataP                    = "--metadata"
	scopesP                      = "--scopes"
	enableStackDriverKubernetesP = "--enable-stackdriver-kubernetes"
	enableAutoUpgradeP           = "--enable-autoupgrade"
	enableAutoRepairP            = "--enable-autorepair"
	quietP                       = "--quiet"

	defaultClusterName = "capi-gcp"
	defaultRegion      = "us-central1"
	defaultZone        = "us-central1-c"
	defaultMachineSize = "e2-medium"
	defaultK8SVersion  = "1.16.13-gke.401"
	defaultKubeconfig  = "kubeconfig"

	kubeconfigVar = "KUBECONFIG"
)

// defaultGCPConfig verify if any optional config data is missing.
func defaultGCPConfig(gcpConfig *GcpConfig) error {
	if gcpConfig.Spec.Region == "" {
		gcpConfig.Spec.Region = defaultRegion
	}
	if gcpConfig.Spec.Zone == "" {
		gcpConfig.Spec.Zone = defaultZone
	}
	if gcpConfig.Metadata.Name == "" {
		gcpConfig.Metadata.Name = defaultClusterName
	}
	if gcpConfig.Spec.Cluster.MachineSize == "" {
		gcpConfig.Spec.Cluster.MachineSize = defaultMachineSize
	}
	if gcpConfig.Spec.Cluster.K8SVersion == "" {
		gcpConfig.Spec.Cluster.K8SVersion = defaultK8SVersion
	}
	if gcpConfig.Spec.Cluster.Kubeconfig == "" {
		gcpConfig.Spec.Cluster.Kubeconfig = defaultKubeconfig
	}
	return nil
}

// prepareGCPCluster logs in, create resource group, etc
func prepareGCPCluster(gcpConfig *GcpConfig, isCreate bool) error {
	// Verify if Google Cloud config file provides all information needed for creating a cluster
	err := defaultGCPConfig(gcpConfig)
	if err != nil {
		return err
	}

	// Get Kubeconfig filename
	volMount := os.Getenv("BOOTSTRAP_VOLUME")
	_, dstMount := GetVolumeMountPoints(volMount)

	gcpProject := gcpConfig.Credentials.Project
	gcpAccount := gcpConfig.Credentials.Account
	gcpCredential := dstMount + "/" + gcpConfig.Credentials.Credential

	clusterName := gcpConfig.Metadata.Name
	region := gcpConfig.Spec.Region
	zone := gcpConfig.Spec.Zone

	machineSize := gcpConfig.Spec.Cluster.MachineSize
	nodeCount := strconv.FormatInt(int64(gcpConfig.Spec.Cluster.Replicas), 10)
	k8sVersion := gcpConfig.Spec.Cluster.K8SVersion
	kubeconfigFile := gcpConfig.Spec.Cluster.Kubeconfig

	// login to GCP account using Service Principal
	err = execute(gcloud, auth, activateServiceAccount, gcpAccount, keyFileP, gcpCredential)
	if err != nil {
		log.Printf("Failed to login into GCP using Service Account\n")
		return err
	}

	// Set project to use to the configuration
	err = execute(gcloud, config, set, project, gcpProject)
	if err != nil {
		log.Printf("Failed to set GCP project to the configuration\n")
		return err
	}

	if isCreate {
		// Creating Google GKE cluster
		err = execute(gcloud, container, clusters, create, clusterName,
			zoneP, zone, nodeLocations, zone,
			numNodesP, nodeCount, machineTypeP, machineSize,
			enableIPAlias, enableAutoUpgradeP, enableAutoRepairP,
			clusterVersionP, k8sVersion)
		if err != nil {
			log.Printf("Failed to create GKE cluster %s in %s region.\n", clusterName, region)
			return err
		}

		// Retrieving the Kubeconfig file for the cluster
		dstKubeconfig := dstMount + "/" + kubeconfigFile
		os.Setenv(kubeconfigVar, dstKubeconfig)
		err = execute(gcloud, container, clusters, getCredentials, clusterName, zoneP, zone)
		if err != nil {
			log.Printf("Failed to retrieve kubeconfig file for GCP cluster %s in %s region.\n", clusterName, region)
			return err
		}

		if _, err := os.Stat(dstKubeconfig); err != nil {
			log.Printf("Failed to retrieve kubeconfig file for GCP cluster %s in %s region.\n", clusterName, region)
			return err
		}
	} else {
		// Delete GCP GKE cluster
		err = execute(gcloud, container, clusters, delete, clusterName, zoneP, zone, quietP)
		if err != nil {
			log.Printf("Failed to delete GKE cluster %s in %s region.\n", clusterName, region)
			return err
		}
	}
	return nil
}
