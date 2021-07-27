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
	az                = "az"
	aks               = "aks"
	login             = "login"
	group             = "group"
	create            = "create"
	delete            = "delete"
	getCredentials    = "get-credentials"
	servicePrincipalP = "--service-principal"
	usernameP         = "--username"
	passwordP         = "--password"
	tenantP           = "--tenant"
	clientSecretP     = "--client-secret"
	resourceGroupP    = "--resource-group"
	locationP         = "--location"
	nameP             = "--name"
	nodeVMSizeP       = "--node-vm-size"
	nodeCountP        = "--node-count"
	k8sVersionP       = "--kubernetes-version"
	generateSSHKeysP  = "--generate-ssh-keys"
	fileP             = "--file"
	yesP              = "--yes"

	defaultRegion        = "centralus"
	defaultResourceGroup = "airship2-aks-rg"
	defaultClusterName   = "capi-azure"
	defaultVMSize        = "Standard_B2s"
	defaultK8SVersion    = "1.21.2"
	defaultKubeconfig    = "kubeconfig"
)

// defaulAzureConfig verify if any optional config data is missing.
func defaulAzureConfig(azConfig *AzureConfig) error {
	if azConfig.Spec.Region == "" {
		azConfig.Spec.Region = defaultRegion
	}
	if azConfig.Spec.ResourceGroup == "" {
		azConfig.Spec.ResourceGroup = defaultResourceGroup
	}
	if azConfig.Metadata.Name == "" {
		azConfig.Metadata.Name = defaultClusterName
	}
	if azConfig.Spec.Cluster.VMSize == "" {
		azConfig.Spec.Cluster.VMSize = defaultVMSize
	}
	if azConfig.Spec.Cluster.K8SVersion == "" {
		azConfig.Spec.Cluster.K8SVersion = defaultK8SVersion
	}
	if azConfig.Spec.Cluster.Kubeconfig == "" {
		azConfig.Spec.Cluster.Kubeconfig = defaultKubeconfig
	}
	return nil
}

// prepareAKSCluster logs in, create resource group, etc
func prepareAKSCluster(azConfig *AzureConfig, isCreate bool) error {
	// Verify if azure config file provides all information needed for creating a cluster
	err := defaulAzureConfig(azConfig)
	if err != nil {
		return err
	}

	tenantID := azConfig.Credentials.Tenant
	clientID := azConfig.Credentials.Client
	clientSecret := azConfig.Credentials.Secret
	region := azConfig.Spec.Region
	resourceGroup := azConfig.Spec.ResourceGroup
	clusterName := azConfig.Metadata.Name
	vmSize := azConfig.Spec.Cluster.VMSize
	nodeCount := strconv.FormatInt(int64(azConfig.Spec.Cluster.Replicas), 10)
	k8sVersion := azConfig.Spec.Cluster.K8SVersion
	kubeconfigFile := azConfig.Spec.Cluster.Kubeconfig

	// login to Azure account using Service Principal
	err = execute(az, login, servicePrincipalP,
		usernameP, clientID,
		passwordP, clientSecret,
		tenantP, tenantID)
	if err != nil {
		log.Printf("Failed to login into Azure using Service Principal\n")
		return err
	}

	if isCreate {
		// Create resource group for the AKS cluster
		err = execute(az, group, create,
			resourceGroupP, resourceGroup,
			locationP, region)
		if err != nil {
			log.Printf("Failed to create resource group %s in %s region.\n", resourceGroup, region)
			return err
		}

		// Creating Azure AKS cluster
		err = execute(az, aks, create,
			resourceGroupP, resourceGroup,
			nameP, clusterName,
			servicePrincipalP, clientID,
			clientSecretP, clientSecret,
			locationP, region,
			nodeVMSizeP, vmSize,
			nodeCountP, nodeCount,
			k8sVersionP, k8sVersion,
			generateSSHKeysP)
		if err != nil {
			log.Printf("Failed to create AKS cluster %s in %s region.\n", clusterName, region)
			return err
		}

		// Get Kubeconfig filename
		volMount := os.Getenv("BOOTSTRAP_VOLUME")
		_, dstMount := GetVolumeMountPoints(volMount)

		kubeconfig := dstMount + "/" + kubeconfigFile

		// Delete existing Kubeconfig file, if any
		_, err = os.Stat(kubeconfig)
		if err == nil {
			err = os.Remove(kubeconfig)
			if err != nil {
				log.Printf("Failed to remove existing kubeconfig file %s.\n", kubeconfig)
				return err
			}
		}

		// Retrieving the Kubeconfig file for the cluster
		err = execute(az, aks, getCredentials,
			resourceGroupP, resourceGroup,
			nameP, clusterName,
			fileP, kubeconfig)
		if err != nil {
			log.Printf("Failed to retrieve kubeconfig file for AKS cluster %s in %s region.\n", clusterName, region)
			return err
		}
	} else {
		// Delete Azure AKS cluster
		err = execute(az, aks, delete,
			resourceGroupP, resourceGroup,
			nameP, clusterName, yesP)
		if err != nil {
			log.Printf("Failed to delete AKS cluster %s in %s region.\n", clusterName, region)
			return err
		}
	}
	return nil
}
