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

// AzureConfig holds configurations for bootstrap steps
type AzureConfig struct {
	// +optional
	Kind string `json:"kind" validate:"required"`

	// +optional
	APIVersion string `json:"apiVersion" validate:"required"`

	// Configuration parameters for metadata
	Metadata *Metadata `json:"metadata"`

	// Configuration parameters for metadata
	Credentials *Credentials `json:"credentials" validate:"required"`

	// Configuration parameters for spec
	Spec *Spec `json:"spec"`
}

// Metadata structure provides the cluster name to assign and labels to the k8s cluster
type Metadata struct {
	Name   string   `json:"name" validate:"required"`
	Labels []string `json:"labels,omitempty"`
}

// Credentials structu provides the credentials to authenticate with Azure Cloud
type Credentials struct {
	Tenant string `json:"tenant" validate:"required"`
	Client string `json:"client" validate:"required"`
	Secret string `json:"secret" validate:"required"`
}

// Spec structure contains the info for the ck8s luster to deploy
type Spec struct {
	Region        string  `json:"region,omitempty"`
	ResourceGroup string  `json:"resourceGroup,omitempty"`
	Cluster       Cluster `json:"cluster"`
}

// Cluster struct provides data for the k8s cluster to deploy
type Cluster struct {
	// Kubernetes version to deploy
	K8SVersion string `json:"k8sVersion,omitempty"`

	// Azure VM size to use for the cluster
	VMSize string `json:"vmSize,omitempty"`

	// Number of nodes to deploy for the cluster
	Replicas uint8 `json:"replicas,omitempty" validate:"gte=1,lte=100"`

	// Kubeconfig filename to save
	Kubeconfig string `json:"kubeconfig,omitempty"`
}

// ReadYAMLFile reads YAML-formatted configuration file and
// de-serializes it to a given object
func ReadYAMLFile(filePath string, cfg *AzureConfig) error {
	data, err := ioutil.ReadFile(filePath)
	if err != nil {
		log.Printf("yamlFile.Get err #%v ", err)
		return err
	}
	return yaml.Unmarshal(data, cfg)
}

// ReadYAMLtoJSON reads YAML-formatted configuration file and
// de-serializes it to a given object
func ReadYAMLtoJSON(filePath string) (string, error) {
	data, err := ioutil.ReadFile(filePath)
	if err != nil {
		log.Printf("Failed to read Azure Ephemeral configuration file: err #%v ", err)

		return "", err
	}
	jsonByte, err := yaml.YAMLToJSON(data)
	if err != nil {
		log.Printf("YAMLtoJSON err #%v ", err)
		return "", err
	}
	jsonStr := string(jsonByte)
	return jsonStr, nil
}

// ValidateConfigFile validates Azure configuration file for the Ephemeral Cluster
func ValidateConfigFile(config *AzureConfig) error {
	var validate *validator.Validate

	validate = validator.New()
	err := validate.Struct(config)
	if err != nil {
		// this check is only needed when your code could produce
		// an invalid value for validation such as interface with nil value.
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
			log.Printf("    Param = %s\n", err.Param())
			log.Println()
		}
		return err
	}
	return nil
}
