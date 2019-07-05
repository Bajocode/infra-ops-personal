#!/bin/bash

CI_NAMESPACE=tekton-pipelines

function install_tiller() {
  kubectl apply -f ./tiller-rbac.yaml
  helm init --service-account tiller --upgrade
  kubectl rollout status deployment tiller-deploy -n kube-system
}

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

function install_tektoncd() {
  kubectl apply -f https://storage.googleapis.com/tekton-releases/latest/release.yaml

kubectl apply -f - <<EOF
---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: tekton-clusterrolebinding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: default
  namespace: $CI_NAMESPACE
EOF

  local token_value=$(kubectl -n $CI_NAMESPACE get secret $(kubectl -n $CI_NAMESPACE get secret | grep ci-sa | awk '{print $1}') -o json | jq -r '.data.token'  | base64 -D)
  local ca_value=kubectl config view --raw -o json | jq -r '.clusters[0].cluster."certificate-authority-data"' | tr -d '"' | base64 -D

  kubectl create secret generic ci-cluster-secret \
    --from-literal tokenKey=$token_value \
    --from-literal caKey=$ca_value \
    -n $CI_NAMESPACE --dry-run -o yaml | kubectl apply -f -
}

function create_ssh_secret() {
  kubectl create secret generic git-secret \
    -n kube-system \
    --from-file=ssh=$HOME/.ssh/id_rsa \
    --from-file=known_hosts=$HOME/.ssh/known_hosts \
    --dry-run -o yaml | kubectl apply -f -
}

install_tiller
install_ingress
install_certmanager
install_tektoncd
create_ssh_secret
