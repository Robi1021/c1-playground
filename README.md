# Playground

- [Playground](#playground)
  - [Start MacOS](#start-macos)
  - [Start Linux](#start-linux)

Ultra fast and slim kubernetes playground

## Requirements

```sh
# install packages
sudo apt update
sudo apt install -y jq apt-transport-https gnupg2 curl nginx

# kubectl
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubectl

# helm
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh

# kind
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.9.0/kind-linux-amd64
chmod +x ./kind
sudo mv kind /usr/local/bin/
```

Modify `/etc/docker/daemon.json` to include

```json
{"insecure-registries": ["172.18.255.1:5000","172.18.255.2:5000","172.18.255.3:5000"]}
```

## Start MacOS (todo)

```sh
./start.sh
./deploy-registry.sh
./deploy-smartcheck.sh
```

```sh
kubectl port-forward -n smartcheck svc/proxy 1443:443
```

Access with browser `https://localhost:1443`

## Start Linux

```sh
./up.sh
./deploy-registry.sh
./deploy-smartcheck.sh
./deploy-proxy.sh
./deploy-container-security.sh
```

## Tests

### Registry

```sh
REGISTRY_NAME="$(jq -r '.registry_name' config.json)"
REGISTRY_NAMESPACE="$(jq -r '.registry_namespace' config.json)"
REGISTRY_USERNAME="$(jq -r '.registry_username' config.json)"
REGISTRY_PASSWORD="$(jq -r '.registry_password' config.json)"
REGISTRY_PORT="$(jq -r '.registry_port' config.json)"
REGISTRY_IP=$(kubectl get svc -n ${REGISTRY_NAMESPACE} ${REGISTRY_NAME} \
              -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

echo ${REGISTRY_PASSWORD} | docker login https://${REGISTRY_IP}:${REGISTRY_PORT} --username ${REGISTRY_USERNAME} --password-stdin

docker pull gcr.io/google-samples/hello-app:1.0
docker tag gcr.io/google-samples/hello-app:1.0 ${REGISTRY_IP}:${REGISTRY_PORT}/hello-app:1.0
docker push ${REGISTRY_IP}:${REGISTRY_PORT}/hello-app:1.0

kubectl create secret docker-registry regcred --docker-server=${REGISTRY_IP}:${REGISTRY_PORT} --docker-username=${REGISTRY_USERNAME} --docker-password=${REGISTRY_PASSWORD} --docker-email=info@mail.com

cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  creationTimestamp: null
  labels:
    app: hello-server
  name: hello-server
spec:
  replicas: 1
  selector:
    matchLabels:
      app: hello-server
  strategy: {}
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: hello-server
    spec:
      containers:
      - image: ${REGISTRY_IP}:${REGISTRY_PORT}/hello-app:1.0
        name: hello-app
        ports:
        - containerPort: 8080
      imagePullSecrets:
      - name: regcred
EOF

kubectl expose deployment hello-server --type LoadBalancer
```

Echo Server

```sh
kubectl create deployment echo --image=inanimate/echo-server
kubectl scale deployment echo --replicas=3
kubectl get deployments
kubectl expose deployment echo --port=8080 --type LoadBalancer
```

### Host Registry

```sh
docker pull gcr.io/google-samples/hello-app:2.0
docker tag gcr.io/google-samples/hello-app:2.0 localhost:5000/hello-app:2.0
docker push localhost:5000/hello-app:2.0
kubectl create deployment hello-server-2 --image=localhost:5000/hello-app:2.0
```

### Container Security

```sh
# try to deploy nginx pod in its own namspace - fail
kubectl create namespace nginx --dry-run=client -o yaml | kubectl apply -f - > /dev/null
kubectl create deployment --image=nginx --namespace nginx nginx
````
