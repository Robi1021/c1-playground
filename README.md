# Playground

- [Playground](#playground)
  - [Requirements and Support Matrix](#requirements-and-support-matrix)
    - [Supported Cluster Variants](#supported-cluster-variants)
    - [Suport Matrix](#suport-matrix)
  - [Prepare your Environment](#prepare-your-environment)
  - [Get the Playground](#get-the-playground)
  - [Configure](#configure)
  - [Start](#start)
    - [Create Playgrounds built-in Cluster](#create-playgrounds-built-in-cluster)
    - [Create GKE, EKS or AKS Clusters](#create-gke-eks-or-aks-clusters)
  - [Deployments](#deployments)
  - [Tear Down](#tear-down)
    - [Tear Down Ubuntu Local, MacOS Local or Cloud9 Local Clusters](#tear-down-ubuntu-local-macos-local-or-cloud9-local-clusters)
    - [Tear Down GKE, EKS or AKS Clusters](#tear-down-gke-eks-or-aks-clusters)
  - [Play with the Playground](#play-with-the-playground)
  - [Demo Scripts](#demo-scripts)
    - [Deployment Control Demo](#deployment-control-demo)
    - [Runtime Security Demo](#runtime-security-demo)
  - [TODO](#todo)

Ultra fast and slim kubernetes playground.

The playground runs on local or Cloud9 based Ubuntu servers, GKE, AKS, EKS and most parts on MacOS as well.

## Requirements and Support Matrix

> ***Note:*** The Playgound is designed to work on these operating systems
>
> - Ubuntu Bionic and newer
> - Cloud9 with Ubuntu
> - MacOS 10+ (INTEL Only)
>
> for a locally running cluster.
>
> The deployment scripts for managed cloud clusters are supporting the following cluster types:
>
> - GKE
> - EKS
> - AKS

### Supported Cluster Variants

Originally, the playground was designed to create a kubernetes cluster locally on the host running the playground scripts. This is still the fastest way of getting a cluster up and running.

In addition to the local cluster, it is also possible to use most functionality of the playground on the managed clusters of the main cloud providers AWS, GCP & Azure as well. Going into this direction requires you to work on a Linux / MacOS shell and an authenticated CLI to the chosen cloud provider (`aws`, `az` or `gcloud`).

Before or after you've authenticated to the cloud, be sure to install the required tools as described in the next section.

Within the directory `clusters` are scripts to rapidly create a kubernetes cluster on the three major public clouds. This comes in handy, if you want to play on these public clouds or have no possibility to run an Ubuntu or MacOS.

> ***NOTE:*** Do not run `up.sh` or `down.sh` when using these clusters.

### Suport Matrix

Add-On | **Ubuntu**<br>*Local* | **MacOS**<br>*Local* | **Cloud9**<br>*Local* | GKE<br>*Cloud* | EKS<br>*Cloud* | AKS<br>*Cloud*
------ | ------ | ------ | ----- | --- | --- | ---
Scanning Scripts | X | X | X | X | X | X
C1CS Admission & Continuous | X | X | X | X | X | X
C1CS Runtime Security | X | | X | X | X | X
C1CS Artifact Scan aaS | X | X | X | X | X | X

*Local* means, the cluster will run on the machine you're working on.

*Cloud* means, that the cluster is a cloud managed cluster using the named service.

*(1)* Depending on the Kernel in use. Currently the kernels 4.15.x and 5.4.x are supported.


## Prepare your Environment

In the following chapters I'm describing on how to prepare for the Playground in various environments. Choose one and proceed afterwards with section [Get the Playground](#get-the-playground).

If you plan to use the built in cluster of the Playground, please follow

- [Getting Started with built in cluster](docs/getting-started-kind.md)

To prepare for the use with a managed cluster, please follow

- [Getting Started with managed clusters](docs/getting-started-managed.md)

## Get the Playground

Clone the repo and install required packages if not available.

```sh
git clone https://github.com/robi1021/c1-playground.git
cd c1-playground
```

In all of these possible environments you're going to run a script called `tools.sh` either on the host running the playground cluster or the host running the CLI tools of the public clouds. This will ensure you have the latest versions of

- `helm`,
- `kind`,
- `docker`,
- `eksctl`,
- `kubectl`,

installed.

Run it with

```sh
./tools.sh
```

The script will attempt to upgrade already installed tools to the latest available version.

## Configure

Please follow the documentation [here](docs/getting-started-configuration.md).

## Start

If you want to deploy the built-in cluster go through the next chapter. If you want to use a cloud managed cluster jump to [Create GKE, EKS or AKS Clusters](#create-gke-eks-or-aks-clusters).

### Create Playgrounds built-in Cluster

Simply run

```sh
# Local built-in Cluster
./up.sh
```

Now, head over to [Deployments](#deployments).

### Create GKE, EKS or AKS Clusters

Run one of the following scripts to quickly create a cluster in the clouds.

```sh
# GKE
./clusters/rapid-gke.sh

# AKS
./clusters/rapid-aks.sh

# EKS
./clusters/rapid-eks.sh
```

You don't need to create a registry here since you're going to use the cloud provided registries GCR, ACR or ECR.

## Deployments

The playground provides a couple of scripts which deploy preconfigured versions of several products. This includes currently:

- Container Security (`./deploy-container-security.sh`)
- Artifact Scan as a Service (`./tmas-install.sh`)

## Tear Down

### Tear Down Ubuntu Local, MacOS Local or Cloud9 Local Clusters

```sh
./down.sh
```

### Tear Down GKE, EKS or AKS Clusters

Run one of the following scripts to quickly tear down a cluster in the clouds. These scripts are created automatically by the cluster scripts.

```sh
# GKE
./rapid-gke-down.sh

# AKS
./rapid-aks-down.sh

# EKS
./rapid-eks-down.sh
```

## Add-Ons

The documentation for the add-ons are located inside the `./docs` directory.

- [Container Security](docs/add-on-container-security.md)

## Play with the Playground

If you wanna play within the playground and you're running it either on Linux or Cloud9, follow the lab guide [Play with the Playground (on Linux & Cloud9)](docs/play-on-linux.md).

If you're running the playground on MacOS, follow the lab guide [Play with the Playground (on MacOS)](docs/play-on-macos.md).

Both guides are basically identical, but since access to some services is different on Linux and MacOS there are two guides available.

### Deployment Control Demo

> ***Storyline:*** A developer wants to try out a new `nginx` image but fails since the image has critical vulnerabilities, he tries to deploy from docker hub etc. Lastly he tries to attach to the pod, which is prevented by Container Security.

To prepare for the demo verify that the cluster policy is set as shown below:

- Pod properties
  - uncheck - containers that run as root
  - Block - containers that run in the host network namespace
  - Block - containers that run in the host IPC namespace
  - Block - containers that run in the host PID namespace
- Container properties
  - Block - containers that are permitted to run as root
  - Block - privileged containers
  - Block - containers with privilege escalation rights
  - Block - containers that can write to the root filesystem
- Image properties
  - Block - images from registries with names that DO NOT EQUAL REGISTRY:PORT
  - uncheck - images with names that
  - Log - images with tags that EQUAL latest
  - uncheck - images with image paths that
- Scan Results
  - Block - images that are not scanned
  - Block - images with malware
  - Log - images with content findings whose severity is CRITICAL OR HIGHER
  - Log - images with checklists whose severity is CRITICAL OR HIGHER
  - Log - images with vulnerabilities whose severity is CRITICAL OR HIGHER
  - Block - images with vulnerabilities whose CVSS attack vector is NETWORK and whose severity is HIGH OR HIGHER
  - Block - images with vulnerabilities whose CVSS attack complexity is LOW and whose severity is HIGH OR HIGHER
  - Block - images with vulnerabilities whose CVSS availability impact is HIGH and whose severity is HIGH OR HIGHER
  - Log - images with a negative PCI-DSS checklist result with severity CRITICAL OR HIGHER
- Kubectl Access
  - Block - attempts to execute in/attach to a container
  - Log - attempts to establish port-forward on a container

Most of it should already configured by the `deploy-container-security.sh` script.

Run the demo with

```sh
./demos/demo-c1cs-dc.sh
```

### Runtime Security Demo

> ***Storyline:*** A kubernetes admin newbie executes some information gathering about the kubernetes cluster from within a running pod. Finally, he gets kicked by Container Security because of the `kubectl` usage.

To successfully run the runtime demo you need adjust the aboves policy slightly.

Change:

- Kubectl Access
  - Log - attempts to execute in/attach to a container

- Exceptions
  - Allow images with paths that equal `docker.io/mawinkler/ubuntu:latest`

Additionally, set the runtime rule `(T1543)Launch Package Management Process in Container` to ***Log***. Normally you'll find that rule in the `*_error` ruleset.

Run the demo with

```sh
./demos/demo-c1cs-rt.sh
```

The demo starts locally on your system, but creates a pod in the `default` namespace of your cluster using a slightly pimped ubuntu image which is pulled from my docker hub account. The main demo runs within that pod on the cluster, not on your local machine.

The Dockerfile for this image is in `./demos/pod/Dockerfile` for you to verify, but you do not need to build it yourself.

## Experimenting

Working with Kubernetes is likely to raise the one or the other challenge.

## TODO

- ...
