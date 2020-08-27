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
	"io"
	"log"
	"os"
	"os/exec"
	"strings"
)

const (
	bootstrapHelpFile = "help.txt"

	// BootstrapCommand environment variable
	bootstrapHome      = "HOME"
	bootstrapCommand   = "BOOTSTRAP_COMMAND"
	bootstrapConfig    = "BOOTSTRAP_CONFIG"
	bootstrapVolume    = "BOOTSTRAP_VOLUME"
	bootstrapVolumeSep = ":"
)

// GetVolumeMountPoints extracts the source and destination of a volume mount
func GetVolumeMountPoints(volumeMount string) (string, string) {
	sepPos := strings.Index(volumeMount, bootstrapVolumeSep)

	srcMountPoint := volumeMount[:sepPos]
	dstMountPoint := volumeMount[sepPos+1:]

	return srcMountPoint, dstMountPoint
}

// Execute bash command
func execute(command string, arg ...string) error {
	cmd := exec.Command(command, arg...)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	if err := cmd.Start(); err != nil {
		log.Printf("Error executing script %s\n", command)
		return err
	}

	if err := cmd.Wait(); err != nil {
		log.Printf("Error waiting for command execution: %s", err.Error())
		return err
	}

	return nil
}

// CreateAKSCluster creates the AKS cluster
func CreateAKSCluster(config *AzureConfig) error {
	return prepareAKSCluster(config, true)
}

// DeleteAKSCluster deletes the AKS cluster
func DeleteAKSCluster(config *AzureConfig) error {
	return prepareAKSCluster(config, false)
}

// HelpAKSCluster returns the help.txt for the AKS cluster
func HelpAKSCluster() error {
	homeDir := os.Getenv(bootstrapHome)
	src := homeDir + "/" + bootstrapHelpFile
	in, err := os.Open(src)
	if err != nil {
		log.Printf("Could not open %s file\n", src)
		return err
	}
	defer in.Close()

	_, dstMountPoint := GetVolumeMountPoints(os.Getenv(bootstrapVolume))
	dst := dstMountPoint + "/" + bootstrapHelpFile
	out, err := os.Create(dst)
	if err != nil {
		log.Printf("Could not create %s file\n", dst)
		return err
	}
	defer out.Close()

	_, err = io.Copy(out, in)
	if err != nil {
		log.Printf("Failed to copy %s file to %s\n", src, dst)
		return err
	}
	return out.Close()
}
