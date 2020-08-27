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
	"flag"
	"log"
	"os"

	"opendev.org/airship/images/bootstrap_capz/config"
)

const (
	createCmd = "create"
	deleteCmd = "delete"
	helpCmd   = "help"
)

func main() {
	var configPath string

	flag.StringVar(&configPath, "c", "", "Path for the Azure bootstrap configuration (yaml) file")
	flag.Parse()

	if configPath == "" {
		volMount := os.Getenv("BOOTSTRAP_VOLUME")
		_, dstMount := config.GetVolumeMountPoints(volMount)
		azureConfigPath := dstMount + "/" + os.Getenv("BOOTSTRAP_CONFIG")
		configPath = azureConfigPath
	}

	configYAML := &config.AzureConfig{}
	err := config.ReadYAMLFile(configPath, configYAML)
	if err != nil {
		log.Printf("Failed to load Azure Bootstrap config file")
		os.Exit(1)
	}

	err = config.ValidateConfigFile(configYAML)
	if err != nil {
		os.Exit(2)
	}

	command := os.Getenv("BOOTSTRAP_COMMAND")
	switch {
	case command == createCmd:
		err = config.CreateAKSCluster(configYAML)
		if err != nil {
			os.Exit(5)
		}
	case command == deleteCmd:
		err = config.DeleteAKSCluster(configYAML)
		if err != nil {
			os.Exit(6)
		}
	case command == helpCmd:
		err = config.HelpAKSCluster()
		if err != nil {
			os.Exit(7)
		}
	default:
		log.Printf("The --command parameter value shall be 'create', 'delete' or 'help'")
		os.Exit(8)
	}
	os.Exit(0)
}
