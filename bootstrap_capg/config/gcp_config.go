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
	"errors"
	"io/ioutil"
	"log"

	"gopkg.in/go-playground/validator.v9"
	"sigs.k8s.io/yaml"
)

// GcpConfig holds configurations for bootstrap steps
type GcpConfig struct {
	// +optional
	Kind string `yaml:"kind" validate:"required"`

	// +optional
	APIVersion string `yaml:"apiVersion" validate:"required"`

	// Configuration parameters for metadata
	Metadata *Metadata `yaml:"metadata" validate:"required"`

	// Configuration parameters for metadata
	Credentials *Credentials `yaml:"credentials" validate:"required"`

	// Configuration parameters for spec
	Spec *Spec `yaml:"spec"`
}

// Metadata structure provides the cluster name to assign and labels to the k8s cluster
type Metadata struct {
	Name   string   `yaml:"name" validate:"required"`
	Labels []string `yaml:"labels,omitempty"`
}

// Credentials structu provides the credentials to authenticate with Azure Cloud
type Credentials struct {
	Project    string `yaml:"project" validate:"required"`
	Account    string `yaml:"account" validate:"required"`
	Credential string `yaml:"credential" validate:"required"`
}

// Spec structure contains the info for the ck8s luster to deploy
type Spec struct {
	Region  string  `yaml:"region,omitempty"`
	Zone    string  `yaml:"zone,omitempty"`
	Cluster Cluster `yaml:"cluster"`
}

// Cluster struct provides data for the k8s cluster to deploy
type Cluster struct {
	// Kubernetes version to deploy
	K8SVersion string `yaml:"k8sVersion,omitempty"`

	// Google Cloud Compote VM size to use for the cluster
	MachineSize string `yaml:"machineSize,omitempty"`

	// Google Cloud Compote disk size to use for the cluster
	DiskSize uint8 `yaml:"diskSize,omitempty" validate:"gte=1"`

	// Number of nodes to deploy for the cluster
	Replicas uint8 `yaml:"replicas,omitempty" validate:"gte=1,lte=100"`

	// Kubeconfig filename to save
	Kubeconfig string `yaml:"kubeconfig,omitempty"`
}

// ReadYAMLFile reads YAML-formatted configuration file and
// de-serializes it to a given object
func ReadYAMLFile(filePath string, cfg *GcpConfig) error {
	data, err := ioutil.ReadFile(filePath)
	if err != nil {
		log.Printf("Failed to read GCP Ephemeral configuration file: err #%v ", err)
		return err
	}
	return yaml.Unmarshal(data, cfg)
}

// ValidateConfigFile validates GCP configuration file for the Ephemeral Cluster
func ValidateConfigFile(config *GcpConfig) error {
	validate := validator.New()
	err := validate.Struct(config)
	if err != nil {
		var invalidError *validator.InvalidValidationError
		if errors.As(err, &invalidError) {
			log.Println(err)
			return err
		}

		log.Printf("Ephemeral cluster configuration file validation failed")
		for _, err := range err.(validator.ValidationErrors) {
			log.Printf("  Namespace = %s\n", err.Namespace())
			log.Printf("    Tag = %s\n", err.Tag())
			log.Printf("    Type = %s\n", err.Type())
			log.Printf("    Value = %s\n", err.Value())
			log.Printf("    Param = %s\n\n", err.Param())
		}
		return err
	}
	return nil
}
