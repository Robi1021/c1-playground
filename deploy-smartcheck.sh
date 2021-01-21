#!/bin/bash

set -e

SC_NAMESPACE="$(jq -r '.smartcheck_namespace' config.json)"
SC_USERNAME="$(jq -r '.smartcheck_username' config.json)"
SC_PASSWORD="$(jq -r '.smartcheck_password' config.json)"
SC_REG_USERNAME="$(jq -r '.smartcheck_reg_username' config.json)"
SC_REG_PASSWORD="$(jq -r '.smartcheck_reg_password' config.json)"
SC_AC="$(jq -r '.activation_key' config.json)"

printf '%s' "smart check namespace"

kubectl create namespace ${SC_NAMESPACE} --dry-run=client -o yaml | kubectl apply -f - > /dev/null

printf ' %s\n' "created"

printf '%s' "smart check overrides"

SC_TEMPPW='justatemppw'
mkdir -p overrides

cat <<EOF >overrides/overrides-image-security.yml
##
## Default value: (none)
activationCode: '${SC_AC}'
auth:
  ## secretSeed is used as part of the password generation process for
  ## all auto-generated internal passwords, ensuring that each installation of
  ## Deep Security Smart Check has different passwords.
  ##
  ## Default value: {must be provided by the installer}
  secretSeed: 'just_anything-really_anything'
  ## userName is the name of the default administrator user that the system creates on startup.
  ## If a user with this name already exists, no action will be taken.
  ##
  ## Default value: administrator
  ## userName: administrator
  userName: '${SC_USERNAME}'
  ## password is the password assigned to the default administrator that the system creates on startup.
  ## If a user with the name 'auth.userName' already exists, no action will be taken.
  ##
  ## Default value: a generated password derived from the secretSeed and system details
  ## password: # autogenerated
  password: '${SC_TEMPPW}'
service:
  ## type is the Kubernetes Service type for the proxy service that acts as
  ## an entry point to the system.
  # type: ClusterIP
  type: LoadBalancer
  ## httpsPort is the port where the service will listen for HTTPS requests.
  httpsPort: 443
  ## httpPort is the port where the service will listen for HTTP requests.
  ## The service will automatically redirect all HTTP requests to HTTPS.
  httpPort: 80
networkPolicy:
  enabled: false
EOF

cat <<EOF >overrides/overrides-image-security-upgrade.yml
registry:
  ## Enable the built-in registry for pre-registry scanning.
  ##
  ## Default value: false
  enabled: true
    ## Authentication for the built-in registry
  auth:
    ## User name for authentication to the registry
    ##
    ## Default value: empty string
    username: '${SC_REG_USERNAME}'
    ## Password for authentication to the registry
    ##
    ## Default value: empty string
    password: '${SC_REG_PASSWORD}'
    ## The amount of space to request for the registry data volume
    ##
    ## Default value: 5Gi
  dataVolume:
    sizeLimit: 10Gi
certificate:
  secret:
    name: k8s-certificate
    certificate: tls.crt
    privateKey: tls.key
EOF

printf ' %s\n' "created"

printf '%s\n' "install smart check"

helm upgrade --namespace ${SC_NAMESPACE} \
  --values overrides/overrides-image-security.yml \
  smartcheck \
  --install \
  --reuse-values \
  https://github.com/deep-security/smartcheck-helm/archive/master.tar.gz > /dev/null

printf '%s' "waiting for smart check to be in active state"

SMARTCHECK_DEPLOYMENTS=$(kubectl -n smartcheck get deployments | grep -c "/")

while [ $(kubectl -n smartcheck get deployments | grep -cE "1/1|2/2|3/3|4/4|5/5") -ne ${SMARTCHECK_DEPLOYMENTS} ]
do
  printf '%s' "."
  sleep 2
done

SC_HOST=$(kubectl get svc -n ${SC_NAMESPACE} proxy \
            -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

printf '\n'
printf '%s\n' "smart check load balancer ip ${SC_HOST}"

printf '%s\n' "executing initial password change"

SC_USERID=$(curl -s -k -X POST https://${SC_HOST}/api/sessions \
              -H "Content-Type: application/json" \
              -H "Api-Version: 2018-05-01" \
              -H "cache-control: no-cache" \
              -d "{\"user\":{\"userid\":\"${SC_USERNAME}\",\"password\":\"${SC_TEMPPW}\"}}" | \
                jq '.user.id' | tr -d '"'  2>/dev/null)
SC_BEARERTOKEN=$(curl -s -k -X POST https://${SC_HOST}/api/sessions \
                  -H "Content-Type: application/json" \
                  -H "Api-Version: 2018-05-01" \
                  -H "cache-control: no-cache" \
                  -d "{\"user\":{\"userid\":\"${SC_USERNAME}\",\"password\":\"${SC_TEMPPW}\"}}" | \
                    jq '.token' | tr -d '"'  2>/dev/null)
X=$(curl -s -k -X POST https://${SC_HOST}/api/users/${SC_USERID}/password \
      -H "Content-Type: application/json" \
      -H "Api-Version: 2018-05-01" \
      -H "cache-control: no-cache" \
      -H "authorization: Bearer ${SC_BEARERTOKEN}" \
      -d "{  \"oldPassword\": \"${SC_TEMPPW}\", \"newPassword\": \"${SC_PASSWORD}\"  }")

printf '%s\n' "configure smart check certificate"

cat <<EOF >certs/req-sc.conf
[req]
  distinguished_name=req
[san]
  subjectAltName=DNS:${SC_HOST//./-}.nip.io
EOF

openssl req -x509 -newkey rsa:4096 -sha256 -days 3650 -nodes \
  -keyout certs/sc.key -out certs/sc.crt \
  -subj "/CN=${SC_HOST//./-}.nip.io" -extensions san -config certs/req-sc.conf &> /dev/null
kubectl create secret tls k8s-certificate --cert=certs/sc.crt --key=certs/sc.key \
  --dry-run=client -n ${SC_NAMESPACE} -o yaml | kubectl apply -f - > /dev/null

printf '%s\n' "upgrade smart check"

helm upgrade --namespace ${SC_NAMESPACE} \
  --values overrides/overrides-image-security-upgrade.yml \
  smartcheck \
  --reuse-values \
  https://github.com/deep-security/smartcheck-helm/archive/master.tar.gz > /dev/null

cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: smartcheck-ingress
  namespace: smartcheck
spec:
  rules:
  - http:
      paths:
        - pathType: ImplementationSpecific
          backend:
            service:
              name: proxy
              port:
                number: 443
EOF

echo "smart check at ${SC_HOST}"