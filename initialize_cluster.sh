#!/bin/sh

function install_tiller() {
  kubectl apply -f ./tiller-rbac.yaml
  helm init --service-account tiller --upgrade
  kubectl rollout status deployment tiller-deploy -n kube-system
}

function install_certmanager() {
  kubectl apply -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.8/deploy/manifests/00-crds.yaml
  helm repo add jetstack https://charts.jetstack.io
  helm repo update
  helm upgrade \
    --install cert-manager \
    --namespace cert-manager \
    jetstack/cert-manager
  kubectl label namespace cert-manager certmanager.k8s.io/disable-validation="true"
}

install_tiller
install_certmanager
