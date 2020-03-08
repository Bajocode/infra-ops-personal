#!/bin/bash

OPS_NAMESPACE=ops

function install_ingress() {
  helm upgrade \
    --install nginx-ingress \
    --namespace kube-system \
    -f ./nginx-ingress-overrides.yaml \
    stable/nginx-ingress
}

function install_certmanager() {
  kubectl apply -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.8/deploy/manifests/00-crds.yaml
  helm repo add jetstack https://charts.jetstack.io
  helm repo update
  helm upgrade \
    --install cert-manager \
    --namespace cert-manager \
    -f ./cert-manager-overrides.yaml \
    jetstack/cert-manager
  kubectl label namespace cert-manager certmanager.k8s.io/disable-validation="true" \
    --overwrite
  kubectl apply -f ./staging-cluster-issuer.yaml
  kubectl apply -f ./production-cluster-issuer.yaml
}

function install_ops_account() {
  kubectl create namespace $OPS_NAMESPACE \
    --dry-run -o yaml | kubectl apply -f -

kubectl apply -f - <<EOF
---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: ops-clusterrolebinding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: default
  namespace: $OPS_NAMESPACE
EOF
}

install_tiller
install_ingress
install_certmanager
install_ops_account
