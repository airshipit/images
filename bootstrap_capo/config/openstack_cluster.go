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
	"errors"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
)

const (
	// Bootstrap container environment variables
	openstackCredential     = "OS_CREDENTIAL_FILE"
	openstackSecurityGroup  = "OS_SECURITY_GROUP"
	openstackCloudName      = "OS_CLOUD"
	openstackMachineSize    = "OS_MACHINE_FLAVOR"
	openstackKubeconfigFile = "OS_KUBECONFIG_FILE"

	bootstrapHelpFile = "help.txt"

	// BootstrapCommand environment variable
	bootstrapHome      = "SRC_DIR"
	bootstrapVolumeSep = ":"
)

// SetOpenstackCloudEnvVars sets the environment variables used by the script
func SetOpenstackCloudEnvVars(config *OpenstackConfig) error {
	err := os.Setenv(openstackCredential, config.Credentials.Credential)
	err = os.Setenv(openstackCloudName, config.Credentials.CloudName)
	err = os.Setenv(openstackSecurityGroup, config.Spec.Cluster.SecurityGroup)
	err = os.Setenv(openstackMachineSize, config.Spec.Cluster.MachineSize)
	err = os.Setenv(openstackKubeconfigFile, config.Spec.Cluster.Kubeconfig)

	if err != nil {
		return err
	}
	return nil
}

// GetVolumeMountPoints extracts the source and destination of a volume mount
func GetVolumeMountPoints(volumeMount string) (string, string, error) {
	if len(volumeMount) == 0 {
		return "", "", errors.New("volume mount is mandatory, please provide volume mount")
	}
	sepPos := strings.Index(volumeMount, bootstrapVolumeSep)
	srcMountPoint := volumeMount[:sepPos]
	dstMountPoint := volumeMount[sepPos+1:]

	return srcMountPoint, dstMountPoint, nil
}

// CreateOSCluster creates the ephemeral K8S cluster in Openstack
func CreateOSCluster() error {
	srcDir := os.Getenv(bootstrapHome)
	shellScriptFile := "./create-k8s-cluster.sh"
	shellScript := filepath.Join(srcDir, shellScriptFile)
	return execute(shellScript)
}

// DeleteOSCluster deletes the ephemeral K8S cluster in Openstack
func DeleteOSCluster() error {
	srcDir := os.Getenv(bootstrapHome)
	shellScriptFile := "./delete-k8s-cluster.sh"
	shellScript := filepath.Join(srcDir, shellScriptFile)
	return execute(shellScript)
}

func execute(shellScript string) error {
	cmd := exec.Command(shellScript)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	log.Printf("Executing script %s\n", shellScript)
	if err := cmd.Start(); err != nil {
		return err
	}
	return cmd.Wait()
}

// HelpOSCluster prints the help information to supplement the creation of K8S ephemeral cluster
func HelpOSCluster() error {
	srcDir := os.Getenv(bootstrapHome)
	src := filepath.Join(srcDir, bootstrapHelpFile)
	b, err := ioutil.ReadFile(src)
	fmt.Fprintln(os.Stdout, string(b))
	return err
}
