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

package main

import (
	"capo/config"
	"log"
	"os"

	"flag"
)

const (
	createCmd = "create"
	deleteCmd = "delete"
	helpCmd   = "help"
)

func main() {
	var configPath string

	flag.StringVar(&configPath, "c", "", "Path for the Openstack Cloud bootstrap configuration (yaml) file")
	flag.Parse()

	volMount := os.Getenv("BOOTSTRAP_VOLUME")

	_, dstMount, err := config.GetVolumeMountPoints(volMount)

	if err != nil {
		log.Printf("Failed to get volume mount, please provide volume mount")
		os.Exit(1)
	}
	openstackConfigPath := dstMount + "/" + os.Getenv("BOOTSTRAP_CONFIG")
	if len(configPath) == 0 {
		configPath = openstackConfigPath
	}

	configYAML := config.OpenstackConfig{}
	err = config.ReadYAMLFile(configPath, &configYAML)
	if err != nil {
		log.Printf("Failed to load Openstack Cloud Bootstrap config file")
		os.Exit(2)
	}

	err = config.SetOpenstackCloudEnvVars(&configYAML)
	if err != nil {
		log.Printf("Failed to set Openstack Cloud environment variables")
		os.Exit(3)
	}

	command := os.Getenv("BOOTSTRAP_COMMAND")
	switch {
	case command == createCmd:
		err = config.CreateOSCluster()
		if err != nil {
			os.Exit(4)
		}
	case command == deleteCmd:
		err = config.DeleteOSCluster()
		if err != nil {
			os.Exit(5)
		}
	case command == helpCmd:
		err = config.HelpOSCluster()
		if err != nil {
			os.Exit(6)
		}
	default:
		log.Printf("The --command parameter value shall be 'create', 'delete' or 'help'")
		os.Exit(7)
	}
	os.Exit(0)
}
