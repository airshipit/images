# GCP Bootstrap Container

This project contains the Go application and configuration files for
implementing the GCP Bootstrap container.

The GCP Bootstrap container is responsible to create or delete a Kubernetes
(K8S) cluster on GCP Cloud platform using the GKE (Google Kubernetes Engine).

## Go Application

The Go application is the bootstrap container orchestrator that is responsible
for translating commands into actions: create, delete, help.

This Go application uses the Ephemeral cluster configuration file
(e.g., gcp-config.yaml) to determine the Google Cloud credentials and
data to use to create or delete the ephemeral cluster.

## Dockerfile

The **Dockerfile** uses a multi-stage builds to first build the Go application
then create the GCP bootstrap container image.

## Build

To build the bootstrap container image, execute the following command:

```bash
make images
```

This command will build the Go application and then create the bootstrap
container image.
