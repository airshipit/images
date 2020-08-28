/*
Copyright 2014 The Kubernetes Authors.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package config

import (
	"io/ioutil"
	"log"

	"sigs.k8s.io/yaml"
)

// OpenstackConfig holds configurations for bootstrap steps
type OpenstackConfig struct {
	// +optional
	Kind string `yaml:"kind,omitempty"`

	// +optional
	APIVersion string `yaml:"apiVersion,omitempty"`

	// Configuration parameters for metadata
	Metadata *Metadata `yaml:"metadata"`

	// Configuration parameters for metadata
	Credentials *Credentials `yaml:"credentials"`

	// Configuration parameters for spec
	Spec *Spec `yaml:"spec"`
}

// Metadata structure provides the cluster name to assign and labels to the k8s cluster
type Metadata struct {
	Name   string   `yaml:"name"`
	Labels []string `yaml:"labels,omitempty"`
}

// Credentials structu provides the credentials to authenticate with Azure Cloud
type Credentials struct {
	Credential string `yaml:"credential"`
	CloudName  string `yaml:"cloudName"`
}

// Spec structure contains the info for the ck8s luster to deploy
type Spec struct {
	Cluster Cluster `yaml:"cluster"`
}

// Cluster struct provides data for the k8s cluster to deploy
type Cluster struct {
	// flavor of VM
	MachineSize string `yaml:"machineSize,omitempty"`

	// Kubeconfig filename to save
	Kubeconfig string `yaml:"kubeconfig,omitempty"`

	// security group
	SecurityGroup string `yaml:"securityGroup,omitempty"`
}

// ReadYAMLFile reads YAML-formatted configuration file and
// de-serializes it to a given object
func ReadYAMLFile(filePath string, cfg *OpenstackConfig) error {
	data, err := ioutil.ReadFile(filePath)
	log.Printf("Attempting to read Openstack bootstrap cluster configuration file at '%s'", filePath)
	if err != nil {
		return err
	}
	return yaml.Unmarshal(data, cfg)
}
