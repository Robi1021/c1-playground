#!/bin/bash

set -e

NAMESPACE="$(jq -r '.services[] | select(.name=="falco") | .namespace' config.json)"
HOSTNAME="$(jq -r '.services[] | select(.name=="falco") | .hostname' config.json)"
SERVICE_NAME="$(jq -r '.services[] | select(.name=="falco") | .proxy_service_name' config.json)"
LISTEN_PORT="$(jq -r '.services[] | select(.name=="falco") | .proxy_listen_port' config.json)"
OS="$(uname)"

if [[ $(kubectl config current-context) =~ gke_.*|aks-.*|.*eksctl.io ]]; then
  echo Running on GKE, AKS or EKS
fi

function create_namespace {
  printf '%s' "Create falco namespace"

  # create service
  cat <<EOF | kubectl apply -f - -o yaml
apiVersion: v1
kind: Namespace
metadata:
  name: ${NAMESPACE}
EOF
  printf '%s\n' " 🍼"
}

function whitelist_namsspace {
  printf '%s\n' "Whitelist namespace"

  # whitelist namespace for falco
  kubectl label namespace ${NAMESPACE} --overwrite ignoreAdmissionControl=true
}

###
# Falco on Darwin
# 1. Install the driver on the host machine
# Clone the Falco project and checkout the tag corresponding to the same Falco version used within the helm chart (0.29.1 in my case), then:

# git checkout 0.29.1
# mkdir build
# cd build
# brew install yaml-cpp grpc
# export OPENSSL_ROOT_DIR=/usr/local/opt/openssl
# cmake ..
# sudo make install_driver
###

function deploy_falco {
  ## deploy falco
  printf '%s\n' "deploy falco"

  helm repo add falcosecurity https://falcosecurity.github.io/charts
  helm repo update

  mkdir -p overrides
  cat <<EOF > overrides/overrides-falco.yaml
auditLog:
  enabled: true
falco:
  jsonOutput: true
  jsonIncludeOutputProperty: true
  grpc:
    enabled: true
  grpcOutput:
    enabled: true
falcosidekick:
  enabled: true
  webui:
    enabled: true
    service:
      type: LoadBalancer
EOF

  # If running on GKE or AKS we switch to eBPF
  if [[ $(kubectl config current-context) =~ gke_.*|aks-.*|.*eksctl.io|kind.* ]]; then
    cat <<EOF >> overrides/overrides-falco.yaml
ebpf:
  enabled: true
EOF
  fi

  cat <<EOF > overrides/custom-rules.yaml
customRules:
EOF

  # If there is a file called `falco/playground_rules_dev.yaml`, we append it to the custom-rules.yaml
  # and skip the playground and additional rule files
  if [ -f "falco/playground_rules_dev.yaml" ]; then
    printf '%s\n' "Playground Dev rules file found"
    echo "  a_playground_rules_dev.yaml: |-" >> overrides/custom-rules.yaml
    cat falco/playground_rules_dev.yaml | sed  -e 's/^/    /' >> overrides/custom-rules.yaml
  else    
    # If there is a file called `falco/playground_rules.yaml`, we append it to the custom-rules.yaml
    if [ -f "falco/playground_rules.yaml" ]; then
      printf '%s\n' "Playground rules file found"
      echo "  a_playground_rules.yaml: |-" >> overrides/custom-rules.yaml
      cat falco/playground_rules.yaml | sed  -e 's/^/    /' >> overrides/custom-rules.yaml
    fi

    # If there is a file called `falco/additional_rules.yaml`, we append it to the custom-rules.yaml
    if [ -f "falco/additional_rules.yaml" ]; then
      printf '%s\n' "Additional rules file found"
      echo "  z_additional_rules.yaml: |-" >> overrides/custom-rules.yaml
      cat falco/additional_rules.yaml | sed  -e 's/^/    /' >> overrides/custom-rules.yaml
    fi
  fi

  # helm delete falco && kubectl delete svc falco-np && rm /tmp/passthrough.conf && sleep 2 && ./deploy-falco.sh 

  # Install Falco
  helm -n ${NAMESPACE} upgrade \
    falco \
    --install \
    --values=overrides/overrides-falco.yaml \
    -f overrides/custom-rules.yaml \
    falcosecurity/falco

  helm -n ${NAMESPACE} upgrade \
    falco-exporter \
    --install \
    falcosecurity/falco-exporter

  # Create NodePort Service to enable K8s Audit
  cat <<EOF | kubectl -n ${NAMESPACE} apply -f -
kind: Service
apiVersion: v1
metadata:
  name: falco-np
spec:
  selector:
    app: falco
  ports:
  - protocol: TCP
    port: 8765
    nodePort: 32765
  type: NodePort
EOF
}

function create_ingress {
    # create ingress for prometheus and grafana

  printf '%s\n' "Create prometheus and grafana ingress"
  cat <<EOF | kubectl apply -f - -o yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/backend-protocol: HTTP
  name: ${SERVICE_NAME}
  namespace: ${NAMESPACE}
spec:
  rules:
    - host: ${HOSTNAME}
      http:
        paths:
        - path: /
          pathType: Prefix
          backend:
            service:
              name: ${SERVICE_NAME}
              port:
                number: ${LISTEN_PORT}
EOF
  printf '%s\n' "Prometheus and grafana ingress created 🍻"
}

if [ "${OS}" == 'Darwin' ]; then
  echo "*** Falco currently not supported on MacOS ***"
  exit 0
fi

create_namespace
whitelist_namsspace
deploy_falco

if [ "${OS}" == 'Linux' ]; then
  # test if we're using a managed kubernetes cluster on GCP, Azure (or AWS)
  if [[ ! $(kubectl config current-context) =~ gke_.*|aks-.*|.*eksctl.io ]]; then
    ./deploy-proxy.sh falco
    HOST_IP=$(hostname -I | awk '{print $1}')
    echo "Falco UI on: http://${HOST_IP}:${LISTEN_PORT}/ui/#/" >> services
  fi
fi
if [ "${OS}" == 'Darwin' ]; then
  create_ingress
fi
