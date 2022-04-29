# Deploy Cloud One Container Security from a Private Registry

- [Deploy Cloud One Container Security from a Private Registry](#deploy-cloud-one-container-security-from-a-private-registry)
  - [Tools](#tools)
  - [Login to the Registries](#login-to-the-registries)
  - [Container Security - Pull,Tag, & Push](#container-security---pulltag--push)
  - [Smart Check - Pull,Tag, & Push](#smart-check---pulltag--push)

## Tools

Used tools:

- Docker
- yq, awk, helm

Get `yq`

```sh
curl -L https://github.com/mikefarah/yq/releases/download/v4.24.2/yq_linux_amd64.tar.gz -o yq_linux_amd64.tar.gz
tar xfvz yq_linux_amd64.tar.gz
sudo cp yq_linux_amd64 /usr/local/bin/yq
```

## Login to the Registries

```sh
export REGISTRY=172.250.255.1:5000
export USERNAME=admin
export PASSWORD=trendmicro

# Login to Docker Registry
docker login

# Login to private Registry
echo ${PASSWORD} | docker login https://${REGISTRY} --username ${USERNAME} --password-stdin
```

## Container Security - Pull,Tag, & Push

```sh
# Enumerate the Images
curl -L https://github.com/trendmicro/cloudone-container-security-helm/archive/master.tar.gz -o master-cs.tar.gz
tar xfvz master-cs.tar.gz
export TAG=$(yq '.images.defaults.tag' cloudone-container-security-helm-master/values.yaml)
echo ${TAG}

# Pull Smart Check images from Dockerhub.
awk -v tag=$TAG '$1 == "repository:" {printf "trendmicrocloudone/%s:%s\n",$2,tag;}' \
  cloudone-container-security-helm-master/values.yaml | xargs -I {} docker pull {}

# Tag the images with your target registry information, making sure to preserve the original image name.
awk -v tag=$TAG '$1 == "repository:" {printf "trendmicrocloudone/%s:%s\n",$2,tag;}' \
  cloudone-container-security-helm-master/values.yaml | xargs -I {} docker tag {} ${REGISTRY}/{}

# Push the images to the private registry
awk -v tag=$TAG '$1 == "repository:" {printf "trendmicrocloudone/%s:%s\n",$2,tag;}' \
  cloudone-container-security-helm-master/values.yaml | xargs -I {} docker push ${REGISTRY}/{}

# Create image pull secret
kubectl create secret docker-registry regcred \
  --docker-server=${REGISTRY} \
  --docker-username=${USERNAME} \
  --docker-password=${PASSWORD} \
  --namespace=container-security
```

Update Container Securities `overrides.yaml` to override the default source registry with your private registry:

```yaml
...
images:
  defaults:
    registry: [REGISTRY]
    tag: [TAG]
    imagePullSecret: regcred
```

Example:

```yaml
...
images:
  defaults:
    registry: 172.250.255.1:5000
    tag: 2.2.9
    imagePullSecret: regcred
```

Deploy Container Security.

```sh
helm install \
    container-security \
    --values overrides.yaml \
    --namespace trendmicro-system \
    --install \
  https://github.com/trendmicro/cloudone-container-security-helm/archive/master.tar.gz
```

## Smart Check - Pull,Tag, & Push

```sh
# Enumerate the Images
curl -L https://github.com/deep-security/smartcheck-helm/archive/master.tar.gz -o master-dssc.tar.gz
tar xfvz master-dssc.tar.gz
export TAG=$(yq '.images.defaults.tag' smartcheck-helm-master/values.yaml)
echo ${TAG}

# Pull Smart Check images from Dockerhub.
awk -v tag=$TAG '$1 == "repository:" {printf "deepsecurity/%s:%s\n",$2,tag;}' \
  smartcheck-helm-master/values.yaml | xargs -I {} docker pull {}

# Tag the images with your target registry information, making sure to preserve the original image name.
awk -v tag=$TAG '$1 == "repository:" {printf "deepsecurity/%s:%s\n",$2,tag;}' \
  smartcheck-helm-master/values.yaml | xargs -I {} docker tag {} ${REGISTRY}/{}

# Push the images to the private registry
awk -v tag=$TAG '$1 == "repository:" {printf "deepsecurity/%s:%s\n",$2,tag;}' \
  smartcheck-helm-master/values.yaml | xargs -I {} docker push ${REGISTRY}/{}

# Create image pull secret
kubectl create secret docker-registry regcred \
  --docker-server=${REGISTRY} \
  --docker-username=${USERNAME} \
  --docker-password=${PASSWORD} \
  --namespace=smartcheck
```

Update Container Securities `overrides.yaml` to override the default source registry with your private registry:

```yaml
...
images:
  defaults:
    registry: [REGISTRY]
    tag: [TAG]
    imagePullSecret: regcred
```

Example:

```yaml
...
images:
  defaults:
    registry: 172.250.255.1:5000
    tag: 1.2.76
    imagePullSecret: regcred
```

Deploy Smart Check

```sh
helm install \
    smartcheck \
    --values overrides.yaml \
    --namespace smartcheck \
    --install \
  https://github.com/deep-security/smartcheck-helm/archive/master.tar.gz
```