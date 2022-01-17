#!/bin/bash

# Exports
export AWS_REGION=eu-central-1
export KEY_NAME=playground-$(openssl rand -hex 4)
aws ec2 import-key-pair --key-name ${KEY_NAME} --public-key-material fileb://~/.ssh/id_rsa.pub
export KEY_ALIAS_NAME=alias/${KEY_NAME}
aws kms create-alias --alias-name ${KEY_ALIAS_NAME} --target-key-id $(aws kms create-key --query KeyMetadata.Arn --output text)
export MASTER_ARN=$(aws kms describe-key --key-id ${KEY_ALIAS_NAME} --query KeyMetadata.Arn --output text)
echo "export MASTER_ARN=${MASTER_ARN}" | tee -a ~/.bashrc
export CLUSTER_NAME=$(jq -r '.cluster_name' config.json)-$(openssl rand -hex 4)

cat << EOF | eksctl create cluster -f -
---
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: ${CLUSTER_NAME}
  region: ${AWS_REGION}

managedNodeGroups:
- name: nodegroup
  desiredCapacity: 3
  iam:
    withAddonPolicies:
      albIngress: true

secretsEncryption:
  keyARN: ${MASTER_ARN}
EOF

# Deploy Calico
kubectl apply -f https://raw.githubusercontent.com/aws/amazon-vpc-cni-k8s/master/config/master/calico-operator.yaml
kubectl apply -f https://raw.githubusercontent.com/aws/amazon-vpc-cni-k8s/master/config/master/calico-crs.yaml

echo "Creating rapid-eks-down.sh script"
cat <<EOF >rapid-eks-down.sh
set -e

AWS_REGION=${AWS_REGION}
CLUSTER_NAME=${CLUSTER_NAME}
KEY_NAME=${KEY_NAME}
KEY_ALIAS_NAME=${KEY_ALIAS_NAME}

EXISTING_NAMESPACES=\$(kubectl get ns -o json | jq -r '.items[].metadata.name' | tr '\n' '|')

for NAMESPACE in \$(cat config.json | jq -r '.services[].namespace'); do
  if [ "\$NAMESPACE" != "null" ] && [[ ! "\$NAMESPACE" =~ "kube-system"|"kube-public"|"kube-node-lease" ]]; then
    if [[ \$EXISTING_NAMESPACES == *"\$NAMESPACE"* ]]; then
      kubectl delete namespace \${NAMESPACE}
    fi
  fi
done
eksctl delete cluster --name \${CLUSTER_NAME}
# Delete Keys
aws ec2 delete-key-pair --key-name \${KEY_NAME}
aws kms delete-alias --alias-name \${KEY_ALIAS_NAME}
EOF
chmod +x rapid-eks-down.sh
echo "Run rapid-eks-down.sh to tear down everything"
