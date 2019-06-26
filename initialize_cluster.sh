#!/bin/sh

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
  kubectl apply -f ./tektoncd/docker-gcr-secret.yaml
  kubectl apply -f ./tektoncd/docker-sa.yaml
  helm upgrade \
    --install moby-buildkit \
    --namespace tekton-pipelines \
    ./moby-buildkit
}

install_tiller
install_ingress
install_certmanager
install_tektoncd
