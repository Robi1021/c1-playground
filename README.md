# Playground

- [Playground](#playground)
  - [Requirements and Support Matrix](#requirements-and-support-matrix)
    - [Supported Cluster Variants](#supported-cluster-variants)
    - [Support Matrix](#support-matrix)
  - [Getting Started](#getting-started)
    - [Prepare your Environment](#prepare-your-environment)
    - [Configure](#configure)
    - [Clusters](#clusters)
    - [Deployments](#deployments)
    - [CLI Commands of the Playground](#cli-commands-of-the-playground)
    - [Good to Know](#good-to-know)
  - [Add-Ons Documentation](#add-ons-documentation)
  - [Play with the Playground](#play-with-the-playground)
    - [Demo Scripts](#demo-scripts)
      - [Deployment Control Demo](#deployment-control-demo)
      - [Runtime Security Demo](#runtime-security-demo)
    - [Experimenting](#experimenting)
      - [Migrate](#migrate)

Ultra fast and slim kubernetes playground.

***Latest News***

!!! Announcing the ***Playground SIMPLICITY*** !!!

In a nutshell:

- Bootstrapping directly from the clouds. It will attempt to upgrade already installed tools to the latest available version.  

  ```sh
  curl -fsSL https://raw.githubusercontent.com/mawinkler/c1-playground/simplicity/bin/playground | bash
  ```

- No `git clone`
- No `daemon.json` config
- It got a menu :-). Run it via `playground`.
- Bootstrapping has never been easier!
  ![alt text](images/video-bootstrap.gif "menu")

## Requirements and Support Matrix

> ***Note:*** The Playground is designed to work on these operating systems
>
> - Ubuntu Bionic and newer
> - Cloud9 with Ubuntu
> - MacOS 10+
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

### Support Matrix

Add-On | **Ubuntu**<br>*Local* | **MacOS**<br>*Local* | **Cloud9**<br>*Local* | GKE<br>*Cloud* | EKS<br>*Cloud* | AKS<br>*Cloud*
------ | ------ | ------ | ----- | --- | --- | ---
Internal Registry | X | X | X | | |
Scanning Scripts | X | X | X | X | X | X
C1CS Admission & Continuous | X | X | X | X | X | X
C1CS Runtime Security | X (1) | | X | X | X | X
Falco | X | | X | X | X | X | X
Gatekeeper | X | X | X | X | X | X | X
Open Policy Agent | X | X | X | X | X | X | X
Prometheus & Grafana | X | X | X | X | X | X | X
Starboard | X | X | X | X | X | X | X
Cilium | X | | X | X | X | X | X
Kubescape | X | | X | X | X | X | X
Harbor | X (2) | | | | | |
Smarthome | X (2) | | | | | |
Pipelines | | | | | X | |

*Local* means, the cluster will run on the machine you're working on.

*Cloud* means, that the cluster is a cloud managed cluster using the named service.

*(1)* Depending on the Kernel in use. Currently the kernels 4.15.x and 5.4.x are supported.

*(2)* Currently in beta.

## Getting Started

### Prepare your Environment

In the following chapters I'm describing on how to bootstrap Playground in various environments.

If you plan to use the built in cluster of the Playground, please follow

- [Getting Started with built in cluster](docs/getting-started-kind-simplicity.md)

To prepare for the use with a managed cluster, please follow

- [Getting Started with managed clusters](docs/getting-started-managed-simplicity.md)

After bootstrapping run

```sh
playground
```

from anywhere on your system.

### Configure

From within the main menu choose `Edit Configuration`

Please follow the documentation [here](docs/getting-started-configuration-simplicity.md).

### Clusters

From within the main menu choose `Create Cluster...` and select your desired type.

Depending on where you have deployed the playground you potentially need to ensure an authenticated cloud CLI.

Prerequisites | **Local Cluster** | GKE | EKS | AKS
------ | ------ | ------ | ----- | ---
Ubuntu, MacOS | n/a | `gcloud` | `aws` w/ Access Keys | `az`
Cloud9 | n/a | `gcloud` | `aws` w/ Instance Role (1) | `az`

*(1)* The instance role is automatically created and assigned to the Cloud9 instance during bootstrapping.

Then choose your cluster variant to create.

If you want to tear down your cluster choose `Tear Down Cluster` from within the menu. This will destroy the last cluster you created.

> ***Note:*** Cluster versions are defined by the current defaults of the hyper scaler. The built-in cluster is currently version fixed to kubernetes 1.24.7.

### Deployments

The playground provides a couple of scripts which deploy pre-configured versions of several products. This includes currently:

- Container Security
- Smart Check
- Prometheus & Grafana
- Starboard
- Falco Runtime Security
- Harbor
- Open Policy Agent
- Gatekeeper

Deploy the products via `Deploy...` in the menu.

In addition to the above the playground now supports AWS CodePipelines. The pipeline builds a container image based on a sample repo, scans it with Smart Check and deploys it with integrated Cloud One Application Security to the EKS cluster.

The pipeline requires an EKS with a deployed Smart Check. If everything has been set up, running the script `./deploy-pipeline-aws.sh` should do the trick :-). When you're done with the pipeline run the generated script `./pipeline-aws-down.sh` to tear it down.

### CLI Commands of the Playground

Besides the obvious cli tools like `kubectl`, `docker`, etc. the offers you additional commands shown in the table below:

Command | Function
------- | --------
playground | The playground's menu
scan-image | Scan an image using Smart Check<br>Example:<br>`scan-image nginx:latest`
scan-namespace | Scans all images in use within the current namespace<br>Example:<br>`kubectl config set-context --current --namespace <NAMESPACE>`<br>`scan-namespace`
collect-logs-sc | Collects logs from Smart Check
collect-logs-cs | Collects logs from Container Security
stern | Tail logs from multiple pods simultaneously<br>Example:<br>`stern -n trendmicro-system . -t -s2m`
syft | See [github.com/anchore/syft](https://github.com/anchore/syft)
grype | See [github.com/anchore/grype](https://github.com/anchore/grype)
k9s | See [k9scli.io](https://k9scli.io/)

### Good to Know

If you're curious check out the `templates`-directory which holds the configuration of all components. Modify at your own risk ;-).

## Add-Ons Documentation

The documentation for the add-ons are located inside the `./docs` directory.

- [Cilium](docs/add-on-cilium.md)
- [Container Security](docs/add-on-container-security.md)
- [Falco](docs/add-on-falco.md)
- [Gatekeeper](docs/add-on-gatekeeper.md)
- [Harbor](docs/add-on-harbor.md)
- [Istio](docs/add-on-istio.md)
- [Krew](docs/add-on-krew.md)
- [Kubescape](docs/add-on-kubescape.md)
- [Open Policy Agent](docs/add-on-opa.md)
- [Prometheus & Grafana](docs/add-on-prometheus-grafana.md)
- [Registry](docs/add-on-registry.md)
- [Starboard](docs/add-on-starboard.md)

## Play with the Playground

***TODO UPDATE***

If you wanna play within the playground and you're running it either on Linux or Cloud9, follow the lab guide [Play with the Playground (on Linux & Cloud9)](docs/play-on-linux.md).

If you're running the playground on MacOS, follow the lab guide [Play with the Playground (on MacOS)](docs/play-on-macos.md).

Both guides are basically identical, but since access to some services is different on Linux and MacOS there are two guides available.

If you want to play with pipelines, the Playground now supports CodePipeline on AWS. Follow this [quick documentation](docs/pipelining-on-aws.md) to test it out.

Lastly, there is a [guide](docs/play-with-falco.md) to experiment with the runtime rules built into the playground to play with Falco. The rule set of the playground is located [here](falco/playground_rules.yaml).

### Demo Scripts

The Playground supports automated scripts to demonstrate functionalities of deployments. Currently, there are two scripts available showing some capabilities of Cloud One Container Security.

To run them, ensure to have an EKS cluster up and running and have Smart Check and Container Security deployed.

After configuring the policy and rule set as shown below, you can run the demos with

```sh
# Deployment Control Demo
./demos/demo-c1cs-dc.sh

# Runtime Security Demo
./demos/demo-c1cs-rt.sh
```

#### Deployment Control Demo

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

Run the demo being in the playground directory with

```sh
./demos/demo-c1cs-dc.sh
```

#### Runtime Security Demo

> ***Storyline:*** A kubernetes admin newbie executes some information gathering about the kubernetes cluster from within a running pod. Finally, he gets kicked by Container Security because of the `kubectl` usage.

To successfully run the runtime demo you need adjust the aboves policy slightly.

Change:

- Kubectl Access
  - Log - attempts to execute in/attach to a container

- Exceptions
  - Allow images with paths that equal `docker.io/mawinkler/ubuntu:latest`

Additionally, set the runtime rule `(T1543)Launch Package Management Process in Container` to ***Log***. Normally you'll find that rule in the `*_error` ruleset.

Run the demo being in the playground directory with

```sh
./demos/demo-c1cs-rt.sh
```

The demo starts locally on your system, but creates a pod in the `default` namespace of your cluster using a slightly pimped ubuntu image which is pulled from my docker hub account. The main demo runs within that pod on the cluster, not on your local machine.

The Dockerfile for this image is in `./demos/pod/Dockerfile` for you to verify, but you do not need to build it yourself.

### Experimenting

Working with Kubernetes is likely to raise the one or the other challenge.

#### Migrate

This tries to solve the challenge to migrate workload of an existing cluster using public image registries to a trusted, private one (without breaking the services).

To try it, being in the playground directory run

```sh
migrate/save-cluster.sh
```

This scripts dumps the full cluster to json files separated by namespace. The namespaces `kube-system`, `registry` and `default` are currently excluded.

Effectively, this is a **backup** of your cluster including ConfigMaps and Secrets etc. which you can deploy on a different cluster easily (`kubectl create -f xxx.json`)

To migrate the images currently in use run

```sh
migrate/migrate-images.sh
```

This second script updates the saved manifests in regards the image location to point them to the private registry. If the image has a digest within it's name it is stripped.

The image get's then pulled from the public repo and pushed to the internal one. This is followed by an image scan and the redeployment.

> ***Note:*** at the time of writing the only supported private registry is the internal one.
